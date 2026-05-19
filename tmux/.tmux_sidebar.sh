#!/usr/bin/env bash

set -euo pipefail

sidebar_title="tmux-sidebar"
sidebar_width="${TMUX_SIDEBAR_WIDTH:-28}"
script_path="${TMUX_SIDEBAR_SCRIPT:-$HOME/.tmux_sidebar.sh}"
target_pane="${2:-${TMUX_PANE:-}}"

usage() {
  echo "Usage: $0 toggle-mode|ensure|hide|watch|render"
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

current_session() {
  tmux_value "#{session_id}"
}

sidebar_pane_for_window() {
  local window_id="$1"
  tmux list-panes -t "$window_id" -F "#{pane_id}	#{pane_title}" |
    awk -F '\t' -v title="$sidebar_title" '$2 == title { print $1; exit }'
}

sidebar_enabled() {
  local session_id="$1"
  [ "$(tmux show-option -qv -t "$session_id" @tmux_sidebar_enabled)" = "1" ]
}

set_sidebar_enabled() {
  local session_id="$1"
  local enabled="$2"
  tmux set-option -q -t "$session_id" @tmux_sidebar_enabled "$enabled"
}

sidebar_panes_for_session() {
  local session_id="$1"
  tmux list-panes -s -t "$session_id" -F "#{pane_id}	#{pane_title}" |
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

  active_pane="${target_pane:-$(tmux_value "#{pane_id}")}"
  if [ -z "$active_pane" ]; then
    return
  fi

  if ! sidebar_enabled "$(current_session)"; then
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

hide_sidebar() {
  local session_id="$1"
  local pane_id

  while IFS= read -r pane_id; do
    [ -n "$pane_id" ] || continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done < <(sidebar_panes_for_session "$session_id")
}

toggle_sidebar_mode() {
  local session_id

  session_id="$(current_session)"
  if sidebar_enabled "$session_id"; then
    set_sidebar_enabled "$session_id" 0
    hide_sidebar "$session_id"
    return
  fi

  set_sidebar_enabled "$session_id" 1
  ensure_sidebar
}

render_sidebar() {
  local session_id session_name active_window_id active_window_index active_window_name
  local window_id window_index window_name window_active
  local pane_id pane_index pane_active pane_command pane_path pane_title
  local path_label active_marker window_marker

  session_id="$(current_session)"
  session_name="$(tmux_value "#{session_name}")"
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
  done < <(tmux list-windows -t "$session_id" -F "#{window_id}	#{window_index}	#{window_name}	#{window_active}")

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
  while true; do
    printf '\033[H\033[2J'
    render_sidebar
    sleep 1
  done
}

case "${1:-}" in
  toggle-mode)
    toggle_sidebar_mode
    ;;
  ensure)
    ensure_sidebar
    ;;
  hide)
    set_sidebar_enabled "$(current_session)" 0
    hide_sidebar "$(current_session)"
    ;;
  watch)
    watch_sidebar
    ;;
  render)
    render_sidebar
    ;;
  *)
    usage
    exit 2
    ;;
esac
