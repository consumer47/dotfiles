#!/usr/bin/env bash

# Suspend Wrapper Script
# Checks keep-awake flag before suspending

KEEP_AWAKE_FLAG="/tmp/keep-awake.flag"
SUSPEND_MARKER="/tmp/suspend-marker.flag"

if [ -f "$KEEP_AWAKE_FLAG" ]; then
    notify-send "Suspend Blocked" "Keep-awake mode is active. Disable it to suspend the system." -i dialog-warning
    exit 0
fi

# Create suspend marker (will be removed on resume by a hook if needed)
touch "$SUSPEND_MARKER"

# Pause music and mute audio (if available)
command -v mpc > /dev/null && mpc -q pause
command -v amixer > /dev/null && amixer set Master mute

# Execute suspend
exec systemctl suspend
