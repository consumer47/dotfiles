#!/usr/bin/env bash
# Smart GitLab action for one keybinding:
# - red (failed/canceled): open logs (same behavior as Polybar click)
# - yellow (running/etc): notify with running durations
# - otherwise: notify all good
set -euo pipefail

STATE_ROOT="${GITLAB_WATCH_LOGDIR:-${XDG_STATE_HOME:-$HOME/.local/state}/gitlab-watch}"
STATUS_FILE="$STATE_ROOT/status.json"
TAIL_LINES="${GITLAB_WATCH_RUNNING_TAIL_LINES:-4}"
TAIL_MAX_CHARS="${GITLAB_WATCH_RUNNING_TAIL_MAX_CHARS:-120}"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "$1" "${2:-}" || true
}

is_in_progress() {
  case "$1" in
    running|pending|created|preparing|scheduled|waiting_for_resource|manual) return 0 ;;
    *) return 1 ;;
  esac
}

urlencode_project() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

fmt_age() {
  local iso="$1"
  local ts now diff h m
  ts="$(date -d "$iso" +%s 2>/dev/null || echo 0)"
  now="$(date +%s)"
  if [[ "$ts" -le 0 || "$now" -le "$ts" ]]; then
    printf '%s' "unknown"
    return 0
  fi
  diff=$((now - ts))
  h=$((diff / 3600))
  m=$(((diff % 3600) / 60))
  if [[ "$h" -gt 0 ]]; then
    printf '%sh %sm' "$h" "$m"
  else
    printf '%sm' "$m"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fetch_running_tail() {
  local repo="$1"
  local pipeline_id="$2"
  local host="$3"
  local enc jobs_json job_id trace tail_txt

  command -v glab >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  enc="$(urlencode_project "$repo")"
  jobs_json="$(glab api --hostname "$host" "projects/${enc}/pipelines/${pipeline_id}/jobs" 2>/dev/null || true)"
  [[ -n "$jobs_json" ]] || return 1

  job_id="$(echo "$jobs_json" | jq -r '
    [ .[]
      | select(.status == "running" or .status == "pending" or .status == "created" or .status == "preparing" or .status == "scheduled" or .status == "waiting_for_resource")
      | .id
    ] | first // empty
  ')"
  [[ -n "$job_id" ]] || return 1

  trace="$(glab api --hostname "$host" "projects/${enc}/jobs/${job_id}/trace" 2>/dev/null || true)"
  [[ -n "$trace" ]] || return 1

  tail_txt="$(printf '%s\n' "$trace" \
    | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' \
    | sed 's/\r$//' \
    | tail -n "$TAIL_LINES" \
    | sed -E "s/^(.{${TAIL_MAX_CHARS}}).+$/\1.../")"
  [[ -n "$tail_txt" ]] || return 1

  printf '%s' "$tail_txt"
}

if [[ ! -f "$STATUS_FILE" ]]; then
  notify "GitLab watch" "No status file yet. Run poll first."
  exit 0
fi

if ! jq -e '.repos and (.repos | type == "array")' "$STATUS_FILE" >/dev/null 2>&1; then
  notify "GitLab watch" "Invalid status.json format."
  exit 0
fi

host="$(jq -r '.host // empty' "$STATUS_FILE")"

if jq -e '.repos[]? | select(.status == "failed" or .status == "canceled")' "$STATUS_FILE" >/dev/null; then
  exec "$SCRIPT_DIR/open-failure-logs.sh"
fi

mapfile -t running_rows < <(jq -c '.repos[]? | select(.status != null) | select(.status | IN("running","pending","created","preparing","scheduled","waiting_for_resource","manual"))' "$STATUS_FILE")

if [[ "${#running_rows[@]}" -gt 0 ]]; then
  body=""
  for row in "${running_rows[@]}"; do
    repo="$(echo "$row" | jq -r '.path // "unknown"')"
    started_at="$(echo "$row" | jq -r '.started_at // .updated_at // empty')"
    if [[ -n "$body" ]]; then
      body+=$'\n'
    fi
    if [[ -n "$started_at" ]]; then
      body+="$repo: $(fmt_age "$started_at")"
    else
      body+="$repo: unknown"
    fi
  done
  first_running="$(echo "${running_rows[0]}" | jq -c '.')"
  first_repo="$(echo "$first_running" | jq -r '.path // empty')"
  first_pid="$(echo "$first_running" | jq -r '.pipeline_id // empty')"
  if [[ -n "$host" && -n "$first_repo" && -n "$first_pid" && "$first_pid" != "null" ]]; then
    if tail_txt="$(fetch_running_tail "$first_repo" "$first_pid" "$host")"; then
      body+=$'\n\n'"Last log lines ($first_repo):"$'\n'"$tail_txt"
    fi
  fi
  notify "GitLab: pipeline(s) running" "$body"
  exit 0
fi

notify "GitLab: all good" "All tracked repos are green."
