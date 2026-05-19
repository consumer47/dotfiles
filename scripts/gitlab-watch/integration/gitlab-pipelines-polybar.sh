#!/usr/bin/env bash
# Polybar output: one colored dot per repo from gitlab-watch status.json (no network).
set -euo pipefail

STATE_ROOT="${GITLAB_WATCH_LOGDIR:-${XDG_STATE_HOME:-$HOME/.local/state}/gitlab-watch}"
STATUS_FILE="$STATE_ROOT/status.json"

C_RED='#EC7875'
C_YELLOW='#FDD835'
C_GREEN='#61C766'
C_GRAY='#9E9E9E'

dot() {
  printf '%s' "%{F$1}●%{F-}"
}

inactive_output() {
  local n out i
  n="$(jq '.repos | length' "$STATUS_FILE" 2>/dev/null || echo 0)"
  out="%{F${C_RED}}X%{F-}"
  for ((i = 0; i < n; i++)); do
    out+=" $(dot "$C_GRAY")"
  done
  printf '%s' "$out"
}

if command -v systemctl >/dev/null 2>&1; then
  if ! systemctl --user is-active --quiet gitlab-watch-poll.timer; then
    if [[ -f "$STATUS_FILE" ]]; then
      inactive_output
    else
      printf '%s' "%{F${C_RED}}X%{F-}"
    fi
    exit 0
  fi
fi

if [[ ! -f "$STATUS_FILE" ]]; then
  printf '%s' "%{F${C_GRAY}}?%{F-}"
  exit 0
fi

if ! jq -e '(now - (.updated_at | fromdateiso8601)) < 300' "$STATUS_FILE" >/dev/null 2>&1; then
  n="$(jq '.repos | length' "$STATUS_FILE" 2>/dev/null || echo 0)"
  out=""
  for ((i = 0; i < n; i++)); do
    [[ -n "$out" ]] && out+=" "
    out+="$(dot "$C_GRAY")"
  done
  printf '%s' "$out"
  exit 0
fi

mapfile -t statuses < <(jq -r '.repos[] | .status' "$STATUS_FILE")

out=""
for s in "${statuses[@]}"; do
  [[ -n "$out" ]] && out+=" "
  case "$s" in
    failed|canceled) out+="$(dot "$C_RED")" ;;
    success) out+="$(dot "$C_GREEN")" ;;
    none|null|"") out+="$(dot "$C_GRAY")" ;;
    *) out+="$(dot "$C_YELLOW")" ;;
  esac
done
printf '%s' "$out"
