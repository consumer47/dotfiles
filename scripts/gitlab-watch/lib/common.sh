# shellcheck shell=bash
# Sourced by gitlab-watch scripts — do not execute directly.

gitlab_watch_expand_path() {
  local p=$1
  p="${p/#\~/$HOME}"
  printf '%s' "$p"
}

gitlab_watch_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Valid notify levels (global default: failures).
gitlab_watch_notify_level_is_valid() {
  case "$1" in
    none|failures|finish|all) return 0 ;;
    *) return 1 ;;
  esac
}

# Sets: host_from_file, repos[], gitlab_watch_notify_level_global,
# gitlab_watch_repo_notify_level[], gitlab_watch_logs_root_global (optional),
# gitlab_watch_repo_logs_root[repo] (optional).
gitlab_watch_load_config() {
  local CONFIG_FILE=$1
  host_from_file=""
  repos=()
  gitlab_watch_notify_level_global="failures"
  gitlab_watch_logs_root_global=""
  unset gitlab_watch_repo_notify_level 2>/dev/null || true
  unset gitlab_watch_repo_logs_root 2>/dev/null || true
  declare -gA gitlab_watch_repo_notify_level
  declare -gA gitlab_watch_repo_logs_root

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    local line
    line="$(gitlab_watch_trim "$raw")"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    if [[ "$line" =~ ^host=(.+)$ ]]; then
      host_from_file="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
      continue
    fi
    if [[ "$line" =~ ^host[[:space:]]+(.+)$ ]]; then
      host_from_file="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
      continue
    fi

    if [[ "$line" =~ ^notify-level[[:space:]]+(.+)$ ]]; then
      local lv
      lv="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
      if gitlab_watch_notify_level_is_valid "$lv"; then
        gitlab_watch_notify_level_global="$lv"
      else
        echo "gitlab-watch: ignoring invalid notify-level: $lv" >&2
      fi
      continue
    fi

    if [[ "$line" =~ ^logs-root[[:space:]]+(.+)$ ]]; then
      gitlab_watch_logs_root_global="$(gitlab_watch_expand_path "$(gitlab_watch_trim "${BASH_REMATCH[1]}")")"
      continue
    fi

    if [[ "$line" =~ ^logs-for[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
      local rp lp
      rp="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
      lp="$(gitlab_watch_expand_path "$(gitlab_watch_trim "${BASH_REMATCH[2]}")")"
      [[ -n "$rp" && -n "$lp" ]] && gitlab_watch_repo_logs_root["$rp"]="$lp"
      continue
    fi

    if [[ "$line" =~ ^repo[[:space:]]+(.+)$ ]]; then
      local rest path_override lvl log_ov
      rest="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
      lvl=""
      log_ov=""
      if [[ "$rest" =~ ^(.+)[[:space:]]+logs=([^[:space:]]+)$ ]]; then
        rest="$(gitlab_watch_trim "${BASH_REMATCH[1]}")"
        log_ov="$(gitlab_watch_expand_path "${BASH_REMATCH[2]}")"
      fi
      local last
      last="${rest##* }"
      if gitlab_watch_notify_level_is_valid "$last"; then
        lvl="$last"
        path_override="${rest%"$last"}"
        path_override="$(gitlab_watch_trim "$path_override")"
      else
        path_override="$rest"
      fi
      [[ -n "$path_override" ]] || continue
      repos+=("$path_override")
      [[ -n "$lvl" ]] && gitlab_watch_repo_notify_level["$path_override"]="$lvl"
      [[ -n "$log_ov" ]] && gitlab_watch_repo_logs_root["$path_override"]="$log_ov"
      continue
    fi

    # Legacy: project path (must contain /).
    if [[ "$line" == */* ]]; then
      repos+=("$line")
      continue
    fi

    echo "gitlab-watch: skipping unrecognized line: $line" >&2
  done <"$CONFIG_FILE"
}

# Effective notify level for a repo path.
gitlab_watch_effective_notify_level() {
  local path=$1
  if [[ -n "${gitlab_watch_repo_notify_level[$path]+x}" ]]; then
    printf '%s' "${gitlab_watch_repo_notify_level[$path]}"
  else
    printf '%s' "$gitlab_watch_notify_level_global"
  fi
}

urlencode_project() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

glab_api_get() {
  local path="$1"
  glab api --hostname "$GITLAB_HOST" "$path"
}

repo_dir_safe() {
  local r="$1"
  r="${r//\//__}"
  r="${r//[^a-zA-Z0-9._-]/_}"
  printf '%s' "$r"
}

gitlab_watch_default_state_root() {
  printf '%s' "${GITLAB_WATCH_LOGDIR:-${XDG_STATE_HOME:-$HOME/.local/state}/gitlab-watch}"
}

# Directory for a pipeline's trace logs: BASE/host_safe/repo__/pipeline-ID
# BASE is per-repo logs root, else logs-root, else STATE_ROOT/logs.
gitlab_watch_pipeline_log_dir() {
  local state_root=$1 host_safe=$2 repo=$3 pid=$4
  local rdir base
  rdir="$(repo_dir_safe "$repo")"
  if [[ -n "${gitlab_watch_repo_logs_root[$repo]+x}" ]]; then
    base="${gitlab_watch_repo_logs_root[$repo]}"
  elif [[ -n "$gitlab_watch_logs_root_global" ]]; then
    base="$gitlab_watch_logs_root_global"
  else
    base="$state_root/logs"
  fi
  printf '%s/%s/%s/pipeline-%s' "$base" "$host_safe" "$rdir" "$pid"
}

# Resolve config path: env GITLAB_WATCH_CONFIG or GITLAB_WATCHLIST, else gitlab-watch.conf, else legacy watchlist.conf.
gitlab_watch_resolve_config_file() {
  local root=$1
  local explicit="${GITLAB_WATCH_CONFIG:-${GITLAB_WATCHLIST:-}}"
  if [[ -n "$explicit" ]]; then
    printf '%s' "$explicit"
    return
  fi
  if [[ -f "$root/gitlab-watch.conf" ]]; then
    printf '%s' "$root/gitlab-watch.conf"
  elif [[ -f "$root/watchlist.conf" ]]; then
    echo "gitlab-watch: prefer gitlab-watch.conf; using legacy watchlist.conf" >&2
    printf '%s' "$root/watchlist.conf"
  else
    printf '%s' "$root/gitlab-watch.conf"
  fi
}
