#!/usr/bin/env bash
# Poll latest CI pipeline per repo from config; if the latest run failed, save job logs via glab.
#
# Requires: glab (authenticated for your instance), jq
# Usage:
#   Put "host git.example.com" in gitlab-watch.conf, then ./bin/pipeline-check.sh
#
# Optional env:
#   GITLAB_HOST                    overrides host line in config
#   GITLAB_WATCH_CONFIG            path to config (or deprecated GITLAB_WATCHLIST)
#   GITLAB_WATCH_LOGDIR            state/log root (default: XDG_STATE_HOME/gitlab-watch)
#   GITLAB_WATCH_USE_CACHED_STATUS if 1, use status.json from poll-status (fresh <120s, host match)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITLAB_WATCH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$GITLAB_WATCH_ROOT/lib/common.sh"

CONFIG_FILE=""
FORCE=0

usage() {
  cat <<'EOF'
Poll latest CI pipeline per repo; on failure save job traces via glab.

Put host in gitlab-watch.conf. Copy gitlab-watch.conf.example.

Options:
  --config FILE      default: gitlab-watch.conf (or legacy watchlist.conf)
  --watchlist FILE   same as --config (deprecated)
  --logdir DIR       override log root (default: XDG_STATE_HOME/gitlab-watch)
  --force            re-download traces even if .fetched exists
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|--watchlist) CONFIG_FILE="$2"; shift 2 ;;
    --logdir) GITLAB_WATCH_LOGDIR="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$CONFIG_FILE" ]] || CONFIG_FILE="$(gitlab_watch_resolve_config_file "$GITLAB_WATCH_ROOT")"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found: $CONFIG_FILE (copy gitlab-watch.conf.example)" >&2
  exit 1
fi

gitlab_watch_load_config "$CONFIG_FILE"

GITLAB_HOST="$(gitlab_watch_trim "${GITLAB_HOST:-$host_from_file}")"

if [[ -z "$GITLAB_HOST" ]]; then
  echo "No GitLab host: add a line like \"host git.example.com\" to $CONFIG_FILE or set GITLAB_HOST" >&2
  exit 1
fi

if ! command -v glab >/dev/null 2>&1; then
  echo "glab not found in PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found in PATH" >&2
  exit 1
fi

if [[ ${#repos[@]} -eq 0 ]]; then
  echo "No repos in config (project paths or repo lines): $CONFIG_FILE" >&2
  exit 1
fi

STATE_ROOT="$(gitlab_watch_default_state_root)"
HOST_SAFE="${GITLAB_HOST//./_}"
STATUS_FILE="$STATE_ROOT/status.json"

status_cache_ok() {
  [[ "${GITLAB_WATCH_USE_CACHED_STATUS:-}" == "1" ]] || return 1
  [[ -f "$STATUS_FILE" ]] || return 1
  local fhost
  fhost="$(jq -r '.host // empty' "$STATUS_FILE")"
  [[ "$fhost" == "$GITLAB_HOST" ]] || return 1
  jq -e '(now - (.updated_at | fromdateiso8601)) < 120' "$STATUS_FILE" >/dev/null 2>&1 || return 1
  return 0
}

fetch_failure_traces() {
  local repo="$1" pid="$2" ref="$3" web_url="$4"
  local enc rdir outdir jobs_json count jid jname logfile job_json

  enc="$(urlencode_project "$repo")"
  outdir="$(gitlab_watch_pipeline_log_dir "$STATE_ROOT" "$HOST_SAFE" "$repo" "$pid")"

  if [[ -f "$outdir/.fetched" && "$FORCE" -eq 0 ]]; then
    echo "[$repo] failed log already saved under $outdir (use --force to re-download)"
    return 0
  fi

  mkdir -p "$outdir"

  if ! jobs_json="$(glab_api_get "projects/${enc}/pipelines/${pid}/jobs")"; then
    echo "[$repo] glab api jobs failed" >&2
    return 1
  fi

  count=0
  while IFS= read -r job_json; do
    [[ -z "$job_json" ]] && continue
    jid="$(echo "$job_json" | jq -r '.id')"
    jname="$(echo "$job_json" | jq -r '.name' | sed 's/[\/]/_/g' | tr -cd 'a-zA-Z0-9._+-' | head -c 120)"
    [[ -z "$jname" ]] && jname="job"
    logfile="$outdir/${jname}-${jid}.log"
    if glab_api_get "projects/${enc}/jobs/${jid}/trace" >"$logfile"; then
      echo "[$repo] saved trace: $logfile"
      count=$((count + 1))
    else
      echo "[$repo] could not fetch trace for job $jid ($jname)" >&2
      rm -f "$logfile"
    fi
  done < <(echo "$jobs_json" | jq -c '.[] | select(.status == "failed")')

  if [[ "$count" -eq 0 ]]; then
    echo "[$repo] pipeline failed but no failed jobs with trace (check $web_url)" >&2
  fi

  {
    echo "repo=$repo"
    echo "pipeline_id=$pid"
    echo "ref=$ref"
    echo "web_url=$web_url"
    echo "fetched_at=$(date -Iseconds)"
  } >"$outdir/README.txt"

  touch "$outdir/.fetched"
}

process_repo_live() {
  local repo="$1"
  local enc pipelines_json pid status ref web_url

  enc="$(urlencode_project "$repo")"
  if ! pipelines_json="$(glab_api_get "projects/${enc}/pipelines?per_page=1&order_by=id&sort=desc")"; then
    echo "[$repo] glab api pipelines failed" >&2
    return 1
  fi

  pid="$(echo "$pipelines_json" | jq -r '.[0].id // empty')"
  status="$(echo "$pipelines_json" | jq -r '.[0].status // empty')"
  ref="$(echo "$pipelines_json" | jq -r '.[0].ref // empty')"
  web_url="$(echo "$pipelines_json" | jq -r '.[0].web_url // empty')"

  if [[ -z "$pid" || "$pid" == "null" ]]; then
    echo "[$repo] no pipelines found"
    return 0
  fi

  echo "[$repo] latest pipeline #$pid ($ref) status=$status"

  if [[ "$status" != "failed" ]]; then
    return 0
  fi

  fetch_failure_traces "$repo" "$pid" "$ref" "$web_url"
}

process_from_cache() {
  local line repo status pid ref web_url
  while IFS= read -r line; do
    repo="$(echo "$line" | jq -r '.path')"
    status="$(echo "$line" | jq -r '.status // "none"')"
    pid="$(echo "$line" | jq -r '.pipeline_id // empty')"
    ref="$(echo "$line" | jq -r '.ref // empty')"
    web_url="$(echo "$line" | jq -r '.web_url // empty')"
    if [[ "$status" != "failed" || -z "$pid" || "$pid" == "null" ]]; then
      continue
    fi
    echo "[$repo] cached failed pipeline #$pid ($ref) — fetching traces"
    fetch_failure_traces "$repo" "$pid" "$ref" "$web_url" || true
  done < <(jq -c '.repos[]' "$STATUS_FILE")
}

echo "GitLab host: $GITLAB_HOST"
echo "State: $STATE_ROOT (see gitlab-watch.conf: logs-root, logs-for, or repo … logs=…)"
echo ""

if status_cache_ok; then
  echo "Using fresh status cache: $STATUS_FILE"
  process_from_cache
else
  if [[ "${GITLAB_WATCH_USE_CACHED_STATUS:-}" == "1" ]]; then
    echo "Note: cache missing or stale — fetching pipelines live" >&2
  fi
  for repo in "${repos[@]}"; do
    process_repo_live "$repo" || true
  done
fi
