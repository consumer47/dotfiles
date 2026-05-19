#!/usr/bin/env bash
# Open saved CI failure logs for repos that are currently "failed" in status.json.
# Same log paths as bin/pipeline-check.sh. Env: TERMINAL (default: x-terminal-emulator), EDITOR (default: nvim).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITLAB_WATCH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$GITLAB_WATCH_ROOT/lib/common.sh"

STATE_ROOT="$(gitlab_watch_default_state_root)"
STATUS_FILE="$STATE_ROOT/status.json"
CONFIG_FILE="$(gitlab_watch_resolve_config_file "$GITLAB_WATCH_ROOT")"
[[ -f "$CONFIG_FILE" ]] && gitlab_watch_load_config "$CONFIG_FILE"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "$1" "${2:-}" || true
}

if [[ ! -f "$STATUS_FILE" ]]; then
  notify "No status yet" "Run bin/poll-status.sh or wait for the timer."
  exit 0
fi

GITLAB_HOST="$(jq -r '.host // empty' "$STATUS_FILE")"
[[ -n "$GITLAB_HOST" ]] || { notify "Invalid status.json"; exit 1; }
HOST_SAFE="${GITLAB_HOST//./_}"

logs=()
while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  [[ "$(echo "$row" | jq -r '.status')" != "failed" ]] && continue
  repo="$(echo "$row" | jq -r '.path')"
  pid="$(echo "$row" | jq -r '.pipeline_id // empty')"
  [[ -z "$pid" || "$pid" == "null" ]] && continue
  pdir="$(gitlab_watch_pipeline_log_dir "$STATE_ROOT" "$HOST_SAFE" "$repo" "$pid")"
  [[ -d "$pdir" ]] || continue
  shopt -s nullglob
  for f in "$pdir"/*.log; do
    [[ -f "$f" ]] && logs+=("$f")
  done
  shopt -u nullglob
done < <(jq -c '.repos[]' "$STATUS_FILE")

term="${TERMINAL:-x-terminal-emulator}"
ed="${EDITOR:-nvim}"

open_browser_fallback() {
  local url
  url="$(jq -r '[.repos[] | select(.status == "failed") | .web_url] | map(select(. != null and . != "")) | first // empty' "$STATUS_FILE")"
  if [[ -n "$url" ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" 2>/dev/null &
  fi
}

failed_count="$(jq '[.repos[] | select(.status == "failed")] | length' "$STATUS_FILE")"

if [[ ${#logs[@]} -eq 0 ]]; then
  if [[ "$failed_count" -eq 0 ]]; then
    notify "GitLab watch" "No failed pipelines in the latest poll. Logs are only saved after a failed run (see bin/pipeline-check.sh / systemd timer)."
  else
    notify "Traces not on disk yet" "Failed pipeline(s) in status, but no .log files. Fetch now: systemctl --user start gitlab-watch-poll.service — or: $GITLAB_WATCH_ROOT/bin/pipeline-check.sh (opening GitLab in browser)."
    open_browser_fallback
  fi
  exit 0
fi

# Pause after editor so the terminal window stays visible briefly.
pause='echo; read -rn1 -s -p "Press a key to close..." _'

case "$ed" in
  *vim)
    # All failure logs in tabs (-p). Matches nvim, vim, gvim still gets -p (OK for gvim in terminal wrapper).
    "$term" -e bash -c 'exec "$@"; '"$pause" bash "$ed" -p "${logs[@]}" &
    ;;
  *)
    [[ ${#logs[@]} -gt 1 ]] && notify "Multiple logs" "Opening first of ${#logs[@]} in $ed (use EDITOR=nvim for all in tabs)."
    "$term" -e bash -c 'exec "$@"; '"$pause" bash "$ed" "${logs[0]}" &
    ;;
esac
