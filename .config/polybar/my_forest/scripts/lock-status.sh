#!/usr/bin/env bash

# Lock/Suspend Status Indicator Script
# Detects if system is locked, suspended, or in keep-awake mode

KEEP_AWAKE_FLAG="/tmp/keep-awake.flag"

# Check if keep-awake mode is active
if [ -f "$KEEP_AWAKE_FLAG" ]; then
    echo "⚡"
    exit 0
fi

# Check if i3lock is running (system is locked)
if pgrep -x i3lock > /dev/null; then
    echo "🔒"
    exit 0
fi

# Check if system is suspended
# This is tricky - we can check if systemd suspend target is active
# or check /sys/power/state, but when suspended, the script won't run
# So we'll check for a suspend marker file that gets created before suspend
if [ -f "/tmp/suspend-marker.flag" ]; then
    echo "💤"
    exit 0
fi

# Normal state - unlocked/active
echo "🔓"
