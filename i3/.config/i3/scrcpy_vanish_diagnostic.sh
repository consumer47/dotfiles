#!/usr/bin/bash
# Run this right after the scrcpy window "vanishes" to see why.
# Usage: ~/.config/i3/scrcpy_vanish_diagnostic.sh

LOG=/tmp/scrcpy_vanish_diagnostic.log
echo "=== Scrcpy vanish diagnostic $(date -Iseconds) ===" | tee "$LOG"

echo "" | tee -a "$LOG"
echo "1. Is scrcpy process running?" | tee -a "$LOG"
if pgrep -xa scrcpy; then
  echo "   -> YES" | tee -a "$LOG"
else
  echo "   -> NO (process exited or was killed)" | tee -a "$LOG"
fi

echo "" | tee -a "$LOG"
echo "2. Any window with class or title containing 'scrcpy' in i3 tree?" | tee -a "$LOG"
i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
found=[]
def find(node, path='', in_scratch=False):
    if not isinstance(node, dict): return
    name = (node.get('name') or '')
    if name == '__i3_scratch': in_scratch = True
    wp = node.get('window_properties') or {}
    cls = (wp.get('class') or '')
    title = (wp.get('title') or '')
    if 'scrcpy' in cls.lower() or 'scrcpy' in title.lower():
        loc = 'SCRATCHPAD' if in_scratch else 'WORKSPACE'
        found.append((cls, title[:60], loc, path))
    for k in ('nodes', 'floating_nodes'):
        for i, c in enumerate(node.get(k, [])):
            find(c, path + f'/{k}[{i}]', in_scratch)
find(tree)
for cls, title, loc, path in found:
    print(f'   FOUND: class={repr(cls)} title={repr(title)}')
    print(f'   Location: {loc}')
    print(f'   Path: {path}')
if not found:
    print('   No window with class/title containing scrcpy in i3 tree.')
" 2>&1 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "3. Full dump of scrcpy-related window props (if any):" | tee -a "$LOG"
i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def find(node):
    if not isinstance(node, dict): return
    wp = node.get('window_properties') or {}
    if 'scrcpy' in (wp.get('class') or '').lower() or 'scrcpy' in (wp.get('title') or '').lower():
        print('   ', json.dumps(wp, indent=4))
    for c in node.get('nodes', []) + node.get('floating_nodes', []):
        find(c)
find(tree)
" 2>&1 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "=== End diagnostic. Full log: $LOG ===" | tee -a "$LOG"
