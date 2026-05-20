#!/usr/bin/env bash

set -euo pipefail

sidebar_title="tmux-sidebar"
sidebar_width="${TMUX_SIDEBAR_WIDTH:-28}"
poll_interval="${TMUX_SIDEBAR_POLL_INTERVAL:-0.25}"
script_path="${TMUX_SIDEBAR_SCRIPT:-$HOME/.tmux_sidebar.sh}"
target_pane="${TMUX_PANE:-}"

usage() {
  echo "Usage: $0 open|toggle|toggle-mode|ensure|ensure-all|hide|watch|render|focus|count|move|select|rename|rename-pane|rename-session|rename-window|launch|launch-pane|launch-window|launch-session"
}

tmux_value() {
  if [ -n "$target_pane" ]; then
    tmux display-message -pt "$target_pane" "$1"
  else
    tmux display-message -p "$1"
  fi
}

current_client_key() {
  local client_tty key

  client_tty="$(current_client_tty)"
  key="${client_tty:-no-client}"
  key="${key//\//_}"
  printf '%s' "$key"
}

state_dir() {
  printf '%s/tmux-sidebar-%s' "${XDG_RUNTIME_DIR:-/tmp}" "$(current_client_key)"
}

state_file() {
  printf '%s/%s' "$(state_dir)" "$1"
}

ensure_state_dir() {
  mkdir -p "$(state_dir)"
}

read_state() {
  local file="$1"

  [ -f "$file" ] && cat "$file"
}

write_state() {
  local file="$1"
  local value="$2"

  ensure_state_dir
  printf '%s' "$value" >"$file"
}

shell_quote() {
  printf '%q' "$1"
}

popup_shell() {
  local title="$1"
  local width="$2"
  local height="$3"
  local workdir="$4"
  local command="$5"

  tmux display-popup -E -T "$title" -w "$width" -h "$height" -d "$workdir" "$command" || true
}

tmux_socket_path() {
  local tmux_env="${TMUX:-}"

  if [ -n "$tmux_env" ]; then
    printf '%s' "${tmux_env%%,*}"
  fi
}

current_window() {
  tmux_value "#{window_id}"
}

current_session_name() {
  tmux_value "#{session_name}"
}

current_client_tty() {
  tmux_value "#{client_tty}"
}

sidebar_pane_for_window() {
  local window_id="$1"
  tmux list-panes -t "$window_id" -F "#{pane_id}	#{pane_title}" |
    awk -F '\t' -v title="$sidebar_title" '$2 == title { print $1; exit }'
}

sidebar_mode() {
  local mode

  mode="$(read_state "$(state_file mode)")"
  case "$mode" in
    window|session)
      printf '%s' "$mode"
      ;;
    *)
      printf 'off'
      ;;
  esac
}

sidebar_enabled() {
  [ "$(sidebar_mode)" != "off" ]
}

sidebar_repeat_count() {
  local count

  count="$(read_state "$(state_file repeat)")"
  case "$count" in
    ""|0)
      count=1
      ;;
  esac

  rm -f "$(state_file repeat)"
  printf '%s' "$count"
}

set_sidebar_repeat_count() {
  write_state "$(state_file repeat)" "$1"
}

clear_sidebar_repeat_count() {
  rm -f "$(state_file repeat)"
}

append_sidebar_repeat_count() {
  local digit="$1"
  local current_count next_count

  current_count="$(read_state "$(state_file repeat)")"
  case "$current_count" in
    ""|0)
      next_count="$digit"
      ;;
    *)
      next_count="${current_count}${digit}"
      ;;
  esac

  set_sidebar_repeat_count "$next_count"
  tmux display-message "sidebar count: $next_count"
}

sidebar_count_input() {
  local session_name digit

  session_name="$(current_session_name)"
  digit="${1:-}"
  case "$digit" in
    [1-9])
      append_sidebar_repeat_count "$digit"
      ;;
    0)
      if [ -n "$(read_state "$(state_file repeat)")" ]; then
        append_sidebar_repeat_count "$digit"
      fi
      ;;
  esac
}

sidebar_panes_for_session() {
  local session_name="$1"
  tmux list-panes -s -t "$session_name" -F "#{pane_id}	#{pane_title}" |
    awk -F '\t' -v title="$sidebar_title" '$2 == title { print $1 }'
}

session_sidebar_cursor() {
  local selected current_session session_name

  selected="$(read_state "$(state_file session_cursor)")"
  current_session="$(current_session_name)"
  if [ -z "$selected" ]; then
    selected="$current_session"
  fi

  while IFS= read -r session_name; do
    [ -n "$session_name" ] || continue
    if [ "$session_name" = "$selected" ]; then
      printf '%s' "$selected"
      return
    fi
  done < <(session_names)

  printf '%s' "$current_session"
}

set_session_sidebar_cursor() {
  write_state "$(state_file session_cursor)" "$1"
}

session_names() {
  tmux list-sessions -F "#{session_name}"
}

session_index_for_name() {
  local target="$1"
  local index=0 session_name

  while IFS= read -r session_name; do
    [ -n "$session_name" ] || continue
    index=$((index + 1))
    if [ "$session_name" = "$target" ]; then
      printf '%s' "$index"
      return
    fi
  done < <(session_names)

  printf '0'
}

normalize_session_cursor() {
  local cursor current_session

  cursor="$(session_sidebar_cursor)"
  current_session="$(current_session_name)"
  if [ "$(session_index_for_name "$cursor")" = "0" ]; then
    cursor="$current_session"
    set_session_sidebar_cursor "$cursor"
  fi
  printf '%s' "$cursor"
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
  local active_pane window_id sidebar_pane new_pane session_name

  active_pane="${target_pane:-$(tmux_value "#{pane_id}")}"
  if [ -z "$active_pane" ]; then
    return
  fi

  if ! sidebar_enabled; then
    return
  fi

  session_name="$(current_session_name)"
  window_id="$(current_window)"
  sidebar_pane="$(sidebar_pane_for_window "$window_id")"

  [ -n "$sidebar_pane" ] && return

  new_pane="$(
    tmux split-window -d -t "$active_pane" -h -f -l "$sidebar_width" -P -F "#{pane_id}" "$script_path watch"
  )"
  tmux select-pane -t "$new_pane" -T "$sidebar_title"
}

ensure_sidebar_for_window() {
  local window_id="$1"
  local active_pane sidebar_pane new_pane

  [ -n "$window_id" ] || return

  sidebar_pane="$(sidebar_pane_for_window "$window_id")"
  if [ -n "$sidebar_pane" ]; then
    return
  fi

  active_pane="$(tmux list-panes -t "$window_id" -F "#{pane_id}" | head -n1)"
  [ -n "$active_pane" ] || return

  new_pane="$(
    tmux split-window -d -t "$active_pane" -h -f -l "$sidebar_width" -P -F "#{pane_id}" "$script_path watch"
  )"
  tmux select-pane -t "$new_pane" -T "$sidebar_title"
}

ensure_all_sidebars() {
  local session_name window_id

  session_name="$(current_session_name)"
  while IFS= read -r window_id; do
    [ -n "$window_id" ] || continue
    ensure_sidebar_for_window "$window_id"
  done < <(tmux list-windows -t "$session_name" -F "#{window_id}")
}

focus_sidebar_mode() {
  local client_tty

  client_tty="$(current_client_tty)"

  if sidebar_enabled; then
    ensure_sidebar
    tmux switch-client -c "$client_tty" -T tmux-sidebar 2>/dev/null || true
  else
    clear_sidebar_repeat_count
    tmux switch-client -c "$client_tty" -T root 2>/dev/null || true
  fi
}

hide_sidebar() {
  local session_name="$1"
  local pane_id

  while IFS= read -r pane_id; do
    [ -n "$pane_id" ] || continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done < <(sidebar_panes_for_session "$session_name")
}

set_sidebar_mode() {
  write_state "$(state_file mode)" "$1"
}

clear_sidebar_mode() {
  rm -f "$(state_file mode)"
}

toggle_sidebar_mode() {
  local current_mode next_mode requested_mode

  current_mode="$(sidebar_mode)"
  requested_mode="${1:-}"

  case "$requested_mode" in
    window|session)
      if [ "$current_mode" = "$requested_mode" ]; then
        clear_sidebar_mode
        clear_sidebar_repeat_count
        hide_sidebar "$(current_session_name)"
        tmux switch-client -c "$(current_client_tty)" -T root 2>/dev/null || true
        return
      fi
      next_mode="$requested_mode"
      ;;
    *)
      case "$current_mode" in
        window)
          next_mode="session"
          ;;
        session)
          next_mode="window"
          ;;
        *)
          next_mode="window"
          ;;
      esac
      ;;
  esac

  set_sidebar_mode "$next_mode"
  clear_sidebar_repeat_count
  ensure_all_sidebars
  focus_sidebar_mode
}

open_sidebar_mode() {
  toggle_sidebar_mode "$1"
}

activate_session_sidebar() {
  local session_name target_session client_tty

  session_name="$(current_session_name)"
  target_session="$(normalize_session_cursor)"
  client_tty="$(current_client_tty)"

  clear_sidebar_mode
  hide_sidebar "$session_name"
  clear_sidebar_repeat_count

  if [ -n "$target_session" ]; then
    tmux switch-client -t "$target_session" 2>/dev/null || tmux attach-session -t "$target_session" 2>/dev/null || true
  fi

  tmux switch-client -c "$client_tty" -T root 2>/dev/null || true
}

sidebar_move_window() {
  local session_name direction count i

  session_name="$(current_session_name)"
  direction="${1:-}"
  count="$(sidebar_repeat_count "$session_name")"

  case "$(sidebar_mode)" in
    session)
      sidebar_move_session_cursor "$direction" "$count"
      return
      ;;
  esac

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

sidebar_move_session_cursor() {
  local direction="${1:-}"
  local count="${2:-1}"
  local session_count current_index next_index session_name selected
  local -a session_list=()

  while IFS= read -r session_name; do
    [ -n "$session_name" ] || continue
    session_list+=("$session_name")
  done < <(session_names)

  session_count="${#session_list[@]}"
  [ "$session_count" -gt 0 ] || return

  selected="$(normalize_session_cursor)"
  current_index="$(session_index_for_name "$selected")"
  case "$current_index" in
    ""|0)
      current_index=1
      ;;
  esac

  next_index="$current_index"
  while [ "$count" -gt 0 ]; do
    case "$direction" in
      next)
        next_index=$((next_index % session_count + 1))
        ;;
      previous)
        next_index=$((next_index - 1))
        if [ "$next_index" -lt 1 ]; then
          next_index="$session_count"
        fi
        ;;
    esac
    count=$((count - 1))
  done

  set_session_sidebar_cursor "${session_list[$((next_index - 1))]}"
  focus_sidebar_mode
}

sidebar_select() {
  case "$(sidebar_mode)" in
    session)
      activate_session_sidebar
      ;;
  esac
}

sidebar_move() {
  sidebar_move_window "$1"
}

rename_sidebar_selected() {
  case "$(sidebar_mode)" in
    session)
      rename_current_session
      ;;
    window)
      rename_current_window
      ;;
  esac
}

rename_tmux_target() {
  local kind="$1"
  local target_id="$2"
  local current_name="$3"
  local restore_mode="$4"
  local popup_title="$5"
  local workdir client_tty

  workdir="$(tmux_value "#{pane_current_path}")"
  client_tty="$(current_client_tty)"

  popup_shell "$popup_title" 50% 18% "$workdir" \
    "python3 ~/.tmux_sidebar_rename_prompt.py $(shell_quote "$kind") $(shell_quote "$target_id") $(shell_quote "$current_name") $(shell_quote "$restore_mode") $(shell_quote "$client_tty")"
}

rename_current_pane() {
  rename_tmux_target pane "$(tmux_value "#{pane_id}")" "$(tmux_value "#{pane_title}")" 0 "rename pane: $(tmux_value "#{pane_title}")"
}

rename_current_session() {
  rename_tmux_target session "$(current_session_name)" "$(current_session_name)" 0 "rename session: $(current_session_name)"
}

rename_current_window() {
  rename_tmux_target window "$(current_window)" "$(tmux_value "#{window_name}")" 1 "rename: $(tmux_value "#{window_name}")"
}

launch_pane_shell() {
  local workdir

  workdir="$(tmux_value "#{pane_current_path}")"
  tmux split-window -h -c "$workdir"
}

launch_window_shell() {
  local workdir

  workdir="$(tmux_value "#{pane_current_path}")"
  tmux new-window -c "$workdir"
}

launch_session_shell() {
  local requested_name="${1:-}"
  local session_name workdir socket_path attach_command

  workdir="$(tmux_value "#{pane_current_path}")"
  if [ -n "$requested_name" ]; then
    session_name="$requested_name"
  else
    session_name="shell-$(date +%Y%m%d-%H%M%S)"
  fi

  if ! tmux has-session -t "=${session_name}" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$workdir"
  fi

  socket_path="$(tmux_socket_path)"
  if [ -n "$socket_path" ]; then
    attach_command="TMUX= tmux -S $(shell_quote "$socket_path") attach-session -t $(shell_quote "$session_name")"
  else
    attach_command="TMUX= tmux attach-session -t $(shell_quote "$session_name")"
  fi

  popup_shell "$session_name" 90% 90% "$workdir" "$attach_command"
}

open_launch_mode() {
  local client_tty

  client_tty="$(current_client_tty)"
  tmux switch-client -c "$client_tty" -T launch-target 2>/dev/null || true
  tmux display-message "launch: p pane | w window | s session | q cancel"
}

render_sidebar() {
  local mode current_session session_name current_window_id active_window_index active_window_name
  local window_id window_index window_name window_active
  local pane_id pane_index pane_active pane_command pane_path pane_title
  local path_label active_marker window_marker cursor_session selected_marker
  local -a sessions=()

  mode="$(sidebar_mode)"
  current_session="$(current_session_name)"
  current_window_id="$(tmux_value "#{window_id}")"
  active_window_index="$(tmux_value "#{window_index}")"
  active_window_name="$(tmux_value "#{window_name}")"

  printf '\033[38;5;110m%s\033[0m\n' "$current_session"
  printf '\033[38;5;240m%s\033[0m\n' "----------------------------"
  case "$mode" in
    session)
      printf '\033[1msessions\033[0m\n'
      cursor_session="$(normalize_session_cursor)"
      while IFS= read -r session_name; do
        [ -n "$session_name" ] || continue
        sessions+=("$session_name")
      done < <(session_names)

      for session_name in "${sessions[@]}"; do
        if [ "$session_name" = "$cursor_session" ]; then
          selected_marker=">"
        else
          selected_marker=" "
        fi

        if [ "$session_name" = "$current_session" ]; then
          printf '\033[48;5;110m\033[38;5;235m %s* %s \033[0m\n' \
            "$selected_marker" "${session_name}"
        else
          printf ' %s  \033[38;5;110m%s\033[0m\n' \
            "$selected_marker" "${session_name}"
        fi
      done
      printf '\n\033[38;5;244m%s\033[0m\n' "j/k move, enter attach, b mode"
      ;;
    *)
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
      done < <(tmux list-windows -t "$current_session" -F "#{window_id}	#{window_index}	#{window_name}	#{window_active}")

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
      done < <(tmux list-panes -t "$current_window_id" -F "#{pane_id}	#{pane_index}	#{pane_active}	#{pane_current_command}	#{pane_current_path}	#{pane_title}")

      printf '\n\033[38;5;244m%s\033[0m\n' "prefix b toggles"
      ;;
  esac
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
  open)
    target_pane="${3:-${TMUX_PANE:-}}"
    open_sidebar_mode "${2:-window}"
    ;;
  toggle)
    target_pane="${3:-${TMUX_PANE:-}}"
    toggle_sidebar_mode "${2:-}"
    ;;
  toggle-mode)
    target_pane="${3:-${TMUX_PANE:-}}"
    toggle_sidebar_mode "${2:-}"
    ;;
  count)
    target_pane="${3:-${TMUX_PANE:-}}"
    sidebar_count_input "${2:-}"
    ;;
  move)
    target_pane="${3:-${TMUX_PANE:-}}"
    sidebar_move "${2:-}"
    ;;
  window)
    target_pane="${3:-${TMUX_PANE:-}}"
    sidebar_move "${2:-}"
    ;;
  select)
    target_pane="${2:-${TMUX_PANE:-}}"
    sidebar_select
    ;;
  rename)
    target_pane="${2:-${TMUX_PANE:-}}"
    rename_sidebar_selected
    ;;
  rename-pane)
    target_pane="${2:-${TMUX_PANE:-}}"
    rename_current_pane
    ;;
  rename-session)
    target_pane="${2:-${TMUX_PANE:-}}"
    rename_current_session
    ;;
  rename-window)
    target_pane="${2:-${TMUX_PANE:-}}"
    rename_current_window
    ;;
  launch)
    target_pane="${2:-${TMUX_PANE:-}}"
    open_launch_mode
    ;;
  launch-pane)
    target_pane="${2:-${TMUX_PANE:-}}"
    launch_pane_shell
    ;;
  launch-window)
    target_pane="${2:-${TMUX_PANE:-}}"
    launch_window_shell
    ;;
  launch-session)
    target_pane="${3:-${TMUX_PANE:-}}"
    launch_session_shell "${2:-}"
    ;;
  ensure)
    target_pane="${2:-${TMUX_PANE:-}}"
    ensure_sidebar
    ;;
  ensure-all)
    target_pane="${2:-${TMUX_PANE:-}}"
    ensure_all_sidebars
    ;;
  focus)
    target_pane="${2:-${TMUX_PANE:-}}"
    focus_sidebar_mode
    ;;
  hide)
    target_pane="${2:-${TMUX_PANE:-}}"
    clear_sidebar_mode
    hide_sidebar "$(current_session_name)"
    clear_sidebar_repeat_count "$(current_session_name)"
    tmux switch-client -c "$(current_client_tty)" -T root 2>/dev/null || true
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
