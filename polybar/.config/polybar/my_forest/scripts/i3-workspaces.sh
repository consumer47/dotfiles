#!/usr/bin/env bash

# Display occupied numeric i3 workspaces and make each one clickable.
# The focused workspace is included even when it has no windows.
set -uo pipefail

emit() {
    local tree workspaces
    tree=$(i3-msg -t get_tree 2>/dev/null) || return 0
    workspaces=$(i3-msg -t get_workspaces 2>/dev/null) || return 0

    jq -nr --argjson tree "$tree" --argjson workspaces "$workspaces" '
        [
          $workspaces[]
          | select(.num >= 1 and .num <= 10)
          | . as $ws
          | ([
               $tree
               | ..
               | objects
               | select(.type == "workspace" and .name == $ws.name)
               | (((.nodes // []) + (.floating_nodes // [])) | length)
             ] | add // 0) as $window_count
          | select($window_count > 0 or $ws.focused == true)
          | if $ws.focused then
              "%{A1:i3-msg workspace number " + (.num | tostring) + ":}%{F#ffffff}%{B#3f3f3f} " + (.num | tostring) + " %{B-}%{F-}%{A}"
            else
              "%{A1:i3-msg workspace number " + (.num | tostring) + ":} " + (.num | tostring) + " %{A}"
            end
        ] | join(" ")
    ' 2>/dev/null
}

emit
i3-msg -t subscribe -m '["workspace","window"]' 2>/dev/null |
while IFS= read -r _; do
    emit
done
