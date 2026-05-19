#!/usr/bin/env bash
# Open repo web_url from gitlab-watch status.json by 1-based index.
set -euo pipefail

idx="${1:-}"
if [[ -z "$idx" || ! "$idx" =~ ^[1-9][0-9]*$ ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "Usage: open-repo-by-index.sh <1..N>" || true
  exit 2
fi

STATE_ROOT="${GITLAB_WATCH_LOGDIR:-${XDG_STATE_HOME:-$HOME/.local/state}/gitlab-watch}"
STATUS_FILE="$STATE_ROOT/status.json"
arr_idx=$((idx - 1))

if [[ ! -f "$STATUS_FILE" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "No status yet" "Run poll-status first." || true
  exit 0
fi

url="$(jq -r ".repos[$arr_idx].web_url // empty" "$STATUS_FILE" 2>/dev/null || true)"
path="$(jq -r ".repos[$arr_idx].path // empty" "$STATUS_FILE" 2>/dev/null || true)"

if [[ -z "$url" ]]; then
  msg="No repo $idx URL in status.json"
  [[ -n "$path" ]] && msg="Repo $idx ($path) has no URL"
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "$msg" || true
  exit 0
fi

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$url" >/dev/null 2>&1 &
else
  command -v notify-send >/dev/null 2>&1 && notify-send -a "GitLab watch" "xdg-open not found" "$url" || true
fi
