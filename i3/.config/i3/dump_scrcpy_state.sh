#!/usr/bin/bash
# Dump i3 state for any window that might be scrcpy (by class or title). Run when phone is unlocked to see actual props.
i3-msg -t get_tree | python3 -c "
import json, sys
def walk(node, path='', depth=0):
    if not isinstance(node, dict): return
    indent = '  ' * depth
    wp = node.get('window_properties') or {}
    cls = wp.get('class', '')
    title = wp.get('title', '') or node.get('name', '')
    if 'scrcpy' in (cls or '').lower() or 'scrcpy' in (title or '').lower() or node.get('window'):
        path_str = path + ' -> ' + (node.get('name') or '?')
        print(indent + '---')
        print(indent + 'path:', path_str)
        print(indent + 'window_properties:', wp)
        print(indent + 'id:', node.get('id'), 'type:', node.get('type'), 'name:', repr(node.get('name')))
    for k in ('nodes', 'floating_nodes'):
        for i, c in enumerate(node.get(k, [])):
            walk(c, path + '/' + k + '[' + str(i) + ']', depth + 1)
tree = json.load(sys.stdin)
walk(tree)
print('--- done ---')
"
