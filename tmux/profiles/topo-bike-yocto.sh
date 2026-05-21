TMUX_PROJECT_PROFILE_SESSION="topo-bike-yocto"

tmux_project_profile_config() {
  topo_session_name="$TMUX_PROJECT_PROFILE_SESSION"
  topo_root="$HOME/workbench/topo-bike-yocto-workspace"
  topo_slot_a="$topo_root/topo-bike-linux-yocto-a"
  topo_slot_b="$topo_root/topo-bike-linux-yocto-b"
  topo_slot_c="$topo_root/topo-bike-linux-yocto-c"
  topo_todo_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-profiles/topo-bike-yocto"
}

tmux_project_profile_prepare() {
  tmux_project_profile_config
  project_profile_require_dir "$topo_root"
  project_profile_require_dir "$topo_slot_a"
  project_profile_require_dir "$topo_slot_b"
  project_profile_require_dir "$topo_slot_c"
  mkdir -p "$topo_todo_dir"
}

tmux_project_profile_create() {
  tmux_project_profile_prepare
  tmux new-session -d -s "$topo_session_name" -n root -c "$topo_root"
  tmux_project_profile_update
}

tmux_project_profile_update() {
  tmux_project_profile_prepare
  tmux_project_profile_root_window "$topo_session_name" "$topo_root"
  tmux_project_profile_slot_window "$topo_session_name" "slot-a" "$topo_root" "$topo_slot_a" "tbike-slot-a" "$topo_todo_dir/todo-slot-a.txt"
  tmux_project_profile_slot_window "$topo_session_name" "slot-b" "$topo_root" "$topo_slot_b" "tbike-slot-b" "$topo_todo_dir/todo-slot-b.txt"
  tmux_project_profile_slot_window "$topo_session_name" "slot-c" "$topo_root" "$topo_slot_c" "tbike-slot-c" "$topo_todo_dir/todo-slot-c.txt"
  tmux_project_profile_command_window "$topo_session_name" "rtb-service-pi" "$topo_root" "ssh rtb-service-pi"
  tmux_project_profile_command_window "$topo_session_name" "git" "$topo_root" "lazygit"
  tmux select-window -t "=$topo_session_name:root"
}

tmux_project_profile_window_exists() {
  local session_name="$1"
  local window_name="$2"
  local existing_name

  while IFS= read -r existing_name; do
    [ "$existing_name" = "$window_name" ] && return 0
  done < <(tmux list-windows -t "=$session_name" -F "#{window_name}")

  return 1
}

tmux_project_profile_first_pane() {
  local session_name="$1"
  local window_name="$2"

  tmux list-panes -t "=$session_name:$window_name" -F "#{pane_id}" | head -n1
}

tmux_project_profile_find_titled_pane() {
  local session_name="$1"
  local window_name="$2"
  local pane_title="$3"
  local pane_id existing_title

  while IFS=$'\t' read -r pane_id existing_title; do
    if [ "$existing_title" = "$pane_title" ]; then
      printf '%s' "$pane_id"
      return
    fi
  done < <(tmux list-panes -t "=$session_name:$window_name" -F "#{pane_id}	#{pane_title}")
}

tmux_project_profile_find_role_pane() {
  local session_name="$1"
  local window_name="$2"
  local role="$3"
  local pane_id existing_role

  while IFS=$'\t' read -r pane_id existing_role; do
    if [ "$existing_role" = "$role" ]; then
      printf '%s' "$pane_id"
      return
    fi
  done < <(tmux list-panes -t "=$session_name:$window_name" -F "#{pane_id}	#{@topo_role}")
}

tmux_project_profile_find_command_pane() {
  local session_name="$1"
  local window_name="$2"
  local command="$3"
  local path="$4"
  local pane_id pane_command pane_path

  while IFS=$'\t' read -r pane_id pane_command pane_path; do
    if [ "$pane_command" = "$command" ] && [ "$pane_path" = "$path" ]; then
      printf '%s' "$pane_id"
      return
    fi
  done < <(tmux list-panes -t "=$session_name:$window_name" -F "#{pane_id}	#{pane_current_command}	#{pane_current_path}")
}

tmux_project_profile_root_window() {
  local session_name="$1"
  local root="$2"

  if ! tmux_project_profile_window_exists "$session_name" root; then
    tmux new-window -d -t "=$session_name:" -n root -c "$root"
  fi
}

tmux_project_profile_pane_path() {
  local pane_id="$1"

  tmux display-message -p -t "$pane_id" "#{pane_current_path}"
}

tmux_project_profile_kill_titled_pane() {
  local session_name="$1"
  local window_name="$2"
  local pane_title="$3"
  local pane_id

  pane_id="$(tmux_project_profile_find_titled_pane "$session_name" "$window_name" "$pane_title")"
  if [ -n "$pane_id" ]; then
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  fi
}

tmux_project_profile_set_pane_role() {
  local pane_id="$1"
  local role="$2"

  tmux set-option -q -p -t "$pane_id" @topo_role "$role"
}

tmux_project_profile_command_window() {
  local session_name="$1"
  local window_name="$2"
  local workdir="$3"
  local command="$4"
  local pane_id pane_title

  if tmux_project_profile_window_exists "$session_name" "$window_name"; then
    return
  fi

  pane_title="topo:$window_name"
  pane_id="$(tmux new-window -d -P -F "#{pane_id}" -t "=$session_name:" -n "$window_name" -c "$workdir")"
  tmux select-pane -t "$pane_id" -T "$pane_title"
  tmux send-keys -t "$pane_id" "$command" C-m
}

tmux_project_profile_slot_window() {
  local session_name="$1"
  local window_name="$2"
  local root="$3"
  local slot_dir="$4"
  local ssh_host="$5"
  local todo_file="$6"
  local codex_title ssh_title shell_title todo_title
  local first_pane codex_pane ssh_pane todo_pane

  touch "$todo_file"
  codex_title="topo:$window_name:codex"
  ssh_title="topo:$window_name:ssh"
  shell_title="topo:$window_name:shell"
  todo_title="topo:$window_name:todo"

  if ! tmux_project_profile_window_exists "$session_name" "$window_name"; then
    tmux_project_profile_create_slot_window "$session_name" "$window_name" "$root" "$slot_dir" "$ssh_host" "$todo_file"
    return
  fi

  first_pane="$(tmux_project_profile_first_pane "$session_name" "$window_name")"
  tmux_project_profile_kill_titled_pane "$session_name" "$window_name" "$shell_title"

  codex_pane="$(tmux_project_profile_find_role_pane "$session_name" "$window_name" codex)"
  if [ -z "$codex_pane" ]; then
    codex_pane="$(tmux_project_profile_find_titled_pane "$session_name" "$window_name" "$codex_title")"
  fi
  if [ -z "$codex_pane" ]; then
    codex_pane="$(tmux_project_profile_find_command_pane "$session_name" "$window_name" codex "$root")"
  fi
  if [ -z "$codex_pane" ]; then
    codex_pane="$(tmux split-window -d -v -P -F "#{pane_id}" -t "$first_pane" -c "$root")"
    tmux send-keys -t "$codex_pane" "codex" C-m
  fi
  tmux select-pane -t "$codex_pane" -T "$codex_title"
  tmux_project_profile_set_pane_role "$codex_pane" codex

  todo_pane="$(tmux_project_profile_find_role_pane "$session_name" "$window_name" todo)"
  if [ -z "$todo_pane" ]; then
    todo_pane="$(tmux_project_profile_find_titled_pane "$session_name" "$window_name" "$todo_title")"
  fi
  if [ -z "$todo_pane" ]; then
    todo_pane="$(tmux_project_profile_find_command_pane "$session_name" "$window_name" nvim "$root")"
  fi
  if [ -z "$todo_pane" ]; then
    todo_pane="$(tmux split-window -d -v -P -F "#{pane_id}" -t "$codex_pane" -c "$root" "nvim $(shell_quote "$todo_file")")"
  fi
  tmux select-pane -t "$todo_pane" -T "$todo_title"
  tmux_project_profile_set_pane_role "$todo_pane" todo

  ssh_pane="$(tmux_project_profile_find_role_pane "$session_name" "$window_name" ssh)"
  if [ -z "$ssh_pane" ]; then
    ssh_pane="$(tmux_project_profile_find_titled_pane "$session_name" "$window_name" "$ssh_title")"
  fi
  if [ -n "$ssh_pane" ] && [ "$(tmux_project_profile_pane_path "$ssh_pane")" != "$slot_dir" ]; then
    tmux kill-pane -t "$ssh_pane" 2>/dev/null || true
    ssh_pane=""
  fi
  if [ -z "$ssh_pane" ]; then
    ssh_pane="$(tmux_project_profile_find_command_pane "$session_name" "$window_name" ssh "$slot_dir")"
  fi
  if [ -z "$ssh_pane" ]; then
    ssh_pane="$(tmux split-window -d -v -P -F "#{pane_id}" -t "$todo_pane" -c "$slot_dir")"
    tmux send-keys -t "$ssh_pane" "ssh $ssh_host" C-m
  fi
  tmux select-pane -t "$ssh_pane" -T "$ssh_title"
  tmux_project_profile_set_pane_role "$ssh_pane" ssh

  tmux select-layout -t "=$session_name:$window_name" even-vertical
  tmux swap-pane -d -s "$codex_pane" -t "=$session_name:$window_name.0" 2>/dev/null || true
  tmux swap-pane -d -s "$todo_pane" -t "=$session_name:$window_name.1" 2>/dev/null || true
  tmux swap-pane -d -s "$ssh_pane" -t "=$session_name:$window_name.2" 2>/dev/null || true
  tmux select-layout -t "=$session_name:$window_name" even-vertical
  tmux select-pane -t "$codex_pane"
}

tmux_project_profile_create_slot_window() {
  local session_name="$1"
  local window_name="$2"
  local root="$3"
  local slot_dir="$4"
  local ssh_host="$5"
  local todo_file="$6"
  local codex_pane todo_pane ssh_pane

  codex_pane="$(tmux new-window -d -P -F "#{pane_id}" -t "=$session_name:" -n "$window_name" -c "$root")"
  tmux select-pane -t "$codex_pane" -T "topo:$window_name:codex"
  tmux_project_profile_set_pane_role "$codex_pane" codex
  tmux send-keys -t "$codex_pane" "codex" C-m
  todo_pane="$(tmux split-window -d -v -P -F "#{pane_id}" -t "$codex_pane" -c "$root" "nvim $(shell_quote "$todo_file")")"
  tmux select-pane -t "$todo_pane" -T "topo:$window_name:todo"
  tmux_project_profile_set_pane_role "$todo_pane" todo
  ssh_pane="$(tmux split-window -d -v -P -F "#{pane_id}" -t "$todo_pane" -c "$slot_dir")"
  tmux select-pane -t "$ssh_pane" -T "topo:$window_name:ssh"
  tmux_project_profile_set_pane_role "$ssh_pane" ssh
  tmux send-keys -t "$ssh_pane" "ssh $ssh_host" C-m
  tmux select-layout -t "=$session_name:$window_name" even-vertical
  tmux select-pane -t "$codex_pane"
}
