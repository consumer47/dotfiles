#!/usr/bin/env bash

set -euo pipefail

sidebar_title="tmux-sidebar"
sidebar_width="${TMUX_SIDEBAR_WIDTH:-28}"
poll_interval="${TMUX_SIDEBAR_POLL_INTERVAL:-0.25}"
script_path="${TMUX_SIDEBAR_SCRIPT:-$HOME/.tmux_sidebar.sh}"
target_pane="${TMUX_PANE:-}"

usage() {
  echo "Usage: $0 toggle|toggle-mode|ensure|hide|watch|render|focus|count|window"
}

tmux_value() {
  if [ -n "$target_pane" ]; then
    tmux display-message -pt "$target_pane" "$1"
  else
    tmux display-message -p "$1"
  fi
}

current_window() {
  tmux_value "#{window_id}"
}

current_session_name() {
  tmux_value "#{session_name}"
}

sidebar_pane_for_window() {
  local window_id="$1"
  tmux list-panes -t "$window_id" -F "#{pane_id}	#{pane_title}" |
    awk -F '\t' -v title="$sidebar_title" '$2 == title { print $1; exit }'
}

sidebar_enabled() {
  local session_name="$1"
  [ "$(tmux show-option -qv -t "$session_name" @tmux_sidebar_enabled)" = "1" ]
}

set_sidebar_enabled() {
  local session_name="$1"
  local enabled="$2"
  tmux set-option -q -t "$session_name" @tmux_sidebar_enabled "$enabled"
}

sidebar_repeat_count() {
  local session_name="$1"
  local count

  count="$(tmux show-option -qv -t "$session_name" @tmux_sidebar_repeat)"
  case "$count" in
    ""|0)
      count=1
      ;;
  esac

  tmux set-option -q -u -t "$session_name" @tmux_sidebar_repeat
  printf '%s' "$count"
}

set_sidebar_repeat_count() {
  local session_name="$1"
  local count="$2"
  tmux set-option -q -t "$session_name" @tmux_sidebar_repeat "$count"
}

clear_sidebar_repeat_count() {
  local session_name="$1"
  tmux set-option -q -u -t "$session_name" @tmux_sidebar_repeat
}

append_sidebar_repeat_count() {
  local session_name="$1"
  local digit="$2"
  local current_count next_count

  current_count="$(tmux show-option -qv -t "$session_name" @tmux_sidebar_repeat)"
  case "$current_count" in
    ""|0)
      next_count="$digit"
      ;;
    *)
      next_count="${current_count}${digit}"
      ;;
  esac

  set_sidebar_repeat_count "$session_name" "$next_count"
  tmux display-message "sidebar count: $next_count"
}

sidebar_count_input() {
  local session_name digit

  session_name="$(current_session_name)"
  digit="${1:-}"
  case "$digit" in
    [1-9])
      append_sidebar_repeat_count "$session_name" "$digit"
      ;;
    0)
      if [ -n "$(tmux show-option -qv -t "$session_name" @tmux_sidebar_repeat)" ]; then
        append_sidebar_repeat_count "$session_name" "$digit"
      fi
      ;;
  esac
}

sidebar_panes_for_session() {
  local session_name="$1"
  tmux list-panes -s -t "$session_name" -F "#{pane_id}	#{pane_title}" |
    awk -F '\t' -v title="$sidebar_title" '$2 == title { print $1 }'
}

shorten_path() {
  local path="${1:-}"
  local max="${2:-18}"

  path="${path/#$HOME/~}"
  if [ "${#path}" -le "$max" ]; then
    printf '%s' "$path"
    return
  fi

  printf '...%s' "${path: -$((max - 3))}"
}

ensure_sidebar() {
  local active_pane window_id sidebar_pane new_pane
  local session_name

  active_pane="${target_pane:-$(tmux_value "#{pane_id}")}"
  if [ -z "$active_pane" ]; then
    return
  fi

  session_name="$(current_session_name)"

  if ! sidebar_enabled "$session_name"; then
    return
  fi

  window_id="$(current_window)"
  sidebar_pane="$(sidebar_pane_for_window "$window_id")"

  if [ -n "$sidebar_pane" ]; then
    tmux select-pane -t "$sidebar_pane"
    return
  fi

  new_pane="$(
    tmux split-window -t "$active_pane" -h -f -l "$sidebar_width" -P -F "#{pane_id}" "$script_path watch"
  )"
  tmux select-pane -t "$new_pane" -T "$sidebar_title"
}

focus_sidebar_mode() {
  local session_name window_id sidebar_pane

  session_name="$(current_session_name)"
  window_id="$(current_window)"
  sidebar_pane="$(sidebar_pane_for_window "$window_id")"

  if [ -n "$sidebar_pane" ]; then
    tmux switch-client -T tmux-sidebar 2>/dev/null || true
    return
  fi

  clear_sidebar_repeat_count "$session_name"
  tmux switch-client -T root 2>/dev/null || true
}

hide_sidebar() {
  local session_name="$1"
  local pane_id

  while IFS= read -r pane_id; do
    [ -n "$pane_id" ] || continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done < <(sidebar_panes_for_session "$session_name")
}

toggle_sidebar_mode() {
  local session_name

  session_name="$(current_session_name)"
  if sidebar_enabled "$session_name"; then
    set_sidebar_enabled "$session_name" 0
    hide_sidebar "$session_name"
    clear_sidebar_repeat_count "$session_name"
    tmux switch-client -T root 2>/dev/null || true
    return
  fi

  set_sidebar_enabled "$session_name" 1
  ensure_sidebar
}

sidebar_move_window() {
  local session_name direction count i

  session_name="$(current_session_name)"
  direction="${1:-}"
  count="$(sidebar_repeat_count "$session_name")"

  for i in $(seq 1 "$count"); do
    case "$direction" in
      next)
        tmux next-window -t "$session_name"
        ;;
      previous)
        tmux previous-window -t "$session_name"
        ;;
    esac
  done
}

render_sidebar() {
  local session_name active_window_id active_window_index active_window_name
  local window_id window_index window_name window_active
  local pane_id pane_index pane_active pane_command pane_path pane_title
  local path_label active_marker window_marker

  session_name="$(current_session_name)"
  active_window_id="$(tmux_value "#{window_id}")"
  active_window_index="$(tmux_value "#{window_index}")"
  active_window_name="$(tmux_value "#{window_name}")"

  printf '\033[38;5;110m%s\033[0m\n' "$session_name"
  printf '\033[38;5;240m%s\033[0m\n' "----------------------------"
  printf '\033[1mwindows\033[0m\n'

  while IFS=$'\t' read -r window_id window_index window_name window_active; do
    if [ "$window_active" = "1" ]; then
      window_marker=">"
      printf '\033[48;5;110m\033[38;5;235m %s %s:%s \033[0m\n' \
        "$window_marker" "$window_index" "${window_name:-$window_id}"
    else
      window_marker=" "
      printf ' %s \033[38;5;110m%s\033[0m:%s\n' \
        "$window_marker" "$window_index" "${window_name:-$window_id}"
    fi
  done < <(tmux list-windows -t "$session_name" -F "#{window_id}	#{window_index}	#{window_name}	#{window_active}")

  printf '\n\033[1mpanes in %s:%s\033[0m\n' "$active_window_index" "$active_window_name"

  while IFS=$'\t' read -r pane_id pane_index pane_active pane_command pane_path pane_title; do
    if [ "$pane_title" = "$sidebar_title" ]; then
      continue
    fi

    path_label="$(shorten_path "$pane_path" 16)"
    if [ "$pane_active" = "1" ]; then
      active_marker=">"
      printf '\033[38;5;150m%s %s\033[0m %s\n  \033[38;5;244m%s\033[0m\n' \
        "$active_marker" "$pane_index" "${pane_command:-pane}" "$path_label"
    else
      active_marker=" "
      printf '%s \033[38;5;110m%s\033[0m %s\n  \033[38;5;244m%s\033[0m\n' \
        "$active_marker" "$pane_index" "${pane_command:-pane}" "$path_label"
    fi
  done < <(tmux list-panes -t "$active_window_id" -F "#{pane_id}	#{pane_index}	#{pane_active}	#{pane_current_command}	#{pane_current_path}	#{pane_title}")

  printf '\n\033[38;5;244m%s\033[0m\n' "prefix b toggles"
}

watch_sidebar() {
  local last_frame=""
  local current_frame=""

  while true; do
    current_frame="$(render_sidebar)"
    if [ "$current_frame" != "$last_frame" ]; then
      printf '\033[H\033[2J%s' "$current_frame"
      last_frame="$current_frame"
    fi
    sleep "$poll_interval"
  done
}

case "${1:-}" in
  toggle)
    target_pane="${2:-${TMUX_PANE:-}}"
    toggle_sidebar_mode
    ;;
  toggle-mode)
    target_pane="${2:-${TMUX_PANE:-}}"
    toggle_sidebar_mode
    ;;
  count)
    target_pane="${3:-${TMUX_PANE:-}}"
    sidebar_count_input "${2:-}"
    ;;
  window)
    target_pane="${3:-${TMUX_PANE:-}}"
    sidebar_move_window "${2:-}"
    ;;
  ensure)
    target_pane="${2:-${TMUX_PANE:-}}"
    ensure_sidebar
    ;;
  focus)
    target_pane="${2:-${TMUX_PANE:-}}"
    focus_sidebar_mode
    ;;
  hide)
    target_pane="${2:-${TMUX_PANE:-}}"
    set_sidebar_enabled "$(current_session_name)" 0
    hide_sidebar "$(current_session_name)"
    clear_sidebar_repeat_count "$(current_session_name)"
    tmux switch-client -T root 2>/dev/null || true
    ;;
  watch)
    target_pane="${2:-${TMUX_PANE:-}}"
    watch_sidebar
    ;;
  render)
    target_pane="${2:-${TMUX_PANE:-}}"
    render_sidebar
    ;;
  *)
    usage
    exit 2
    ;;
esac
