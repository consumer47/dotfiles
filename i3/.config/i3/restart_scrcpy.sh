#!/usr/bin/bash
# Kill scrcpy if running, then start it again. Use when the mirror has vanished (e.g. after lock).
pkill -x scrcpy 2>/dev/null
sleep 1
exec "$HOME/.config/i3/start_scrcpy.sh"
