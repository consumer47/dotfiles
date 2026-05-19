#!/usr/bin/bash
# PIN is read from ~/.config/i3/adb_unlock.env (copy from adb_unlock.env.example).
[ -r "$HOME/.config/i3/adb_unlock.env" ] && source "$HOME/.config/i3/adb_unlock.env"

adb shell input keyevent 26  # Power button (wakes the screen)
adb shell input text "${ADB_UNLOCK_PIN:-}"
adb shell input keyevent 66  # Press ENTER to confirm
