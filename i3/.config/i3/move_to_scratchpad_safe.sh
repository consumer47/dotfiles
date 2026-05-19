#!/usr/bin/bash
# Move focused window to scratchpad unless it's scrcpy (so phone window can't vanish by accident).
# Use with: bindsym $mod+Ctrl+s exec --no-startup-id $HOME/.config/i3/move_to_scratchpad_safe.sh
focused_class=$(i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def find_focused(node):
    if not isinstance(node, dict): return None
    if node.get('focused'):
        wp = node.get('window_properties') or {}
        return (wp.get('class') or '')
    for c in node.get('nodes', []) + node.get('floating_nodes', []):
        r = find_focused(c)
        if r is not None: return r
    return None
print(find_focused(tree) or '')
" 2>/dev/null)
if [ "$focused_class" = "scrcpy" ]; then
  notify-send "i3" "Scrcpy window not moved to scratchpad." 2>/dev/null || true
  exit 0
fi
i3-msg 'move scratchpad'
