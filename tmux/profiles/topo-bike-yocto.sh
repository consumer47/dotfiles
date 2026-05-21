TMUX_PROJECT_PROFILE_SESSION="topo-bike-yocto"

tmux_project_profile_create() {
  local session_name="$TMUX_PROJECT_PROFILE_SESSION"
  local root="$HOME/workbench/topo-bike-yocto-workspace"
  local slot_a="$root/topo-bike-linux-yocto-a"
  local slot_b="$root/topo-bike-linux-yocto-b"
  local slot_c="$root/topo-bike-linux-yocto-c"

  project_profile_require_dir "$root"
  project_profile_require_dir "$slot_a"
  project_profile_require_dir "$slot_b"
  project_profile_require_dir "$slot_c"

  tmux new-session -d -s "$session_name" -n root -c "$root"
  tmux_project_profile_slot_window "$session_name" "slot-a" "$root" "$slot_a" "tbike-slot-a"
  tmux_project_profile_slot_window "$session_name" "slot-b" "$root" "$slot_b" "tbike-slot-b"
  tmux_project_profile_slot_window "$session_name" "slot-c" "$root" "$slot_c" "tbike-slot-c"
  tmux_project_profile_command_window "$session_name" "rtb-service-pi" "$root" "ssh rtb-service-pi"
  tmux_project_profile_command_window "$session_name" "git" "$root" "lazygit"
  tmux select-window -t "=$session_name:root"
}

tmux_project_profile_command_window() {
  local session_name="$1"
  local window_name="$2"
  local workdir="$3"
  local command="$4"
  local pane_id

  pane_id="$(tmux new-window -d -P -F "#{pane_id}" -t "=$session_name:" -n "$window_name" -c "$workdir")"
  tmux send-keys -t "$pane_id" "$command" C-m
}

tmux_project_profile_slot_window() {
  local session_name="$1"
  local window_name="$2"
  local root="$3"
  local slot_dir="$4"
  local ssh_host="$5"
  local top_pane

  top_pane="$(tmux new-window -d -P -F "#{pane_id}" -t "=$session_name:" -n "$window_name" -c "$root")"
  tmux send-keys -t "$top_pane" "ssh $ssh_host" C-m
  tmux split-window -d -v -t "$top_pane" -c "$slot_dir"
  tmux select-layout -t "=$session_name:$window_name" even-vertical
  tmux select-pane -t "$top_pane"
}
