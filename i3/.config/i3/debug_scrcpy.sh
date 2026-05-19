#!/usr/bin/bash
# Debug script: log and notify so we can see if the keybind runs.
LOG=/tmp/scrcpy_debug.log
echo "$(date -Iseconds) debug_scrcpy.sh started" >> "$LOG"
echo "  HOME=$HOME" >> "$LOG"
echo "  PATH=$PATH" >> "$LOG"
SCRIPT="$HOME/.config/i3/start_scrcpy.sh"
test -f "$SCRIPT" && echo "  script exists: yes" >> "$LOG" || echo "  script exists: no" >> "$LOG"
test -x "$SCRIPT" && echo "  script executable: yes" >> "$LOG" || echo "  script executable: no" >> "$LOG"
notify-send "scrcpy debug" "Keybind ran. Check $LOG" 2>/dev/null || true
# Actually run start_scrcpy if you want to test that too
if [ -x "$SCRIPT" ]; then
  "$SCRIPT" >> "$LOG" 2>&1
  echo "$(date -Iseconds) start_scrcpy.sh finished with $?" >> "$LOG"
else
  echo "$(date -Iseconds) start_scrcpy.sh not executable, not running" >> "$LOG"
fi
