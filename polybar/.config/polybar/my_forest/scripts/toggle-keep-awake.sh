#!/usr/bin/env bash

# Toggle Keep-Awake Mode
# Prevents system from locking or suspending

KEEP_AWAKE_FLAG="/tmp/keep-awake.flag"
NOTIFY_CMD="notify-send"

if [ -f "$KEEP_AWAKE_FLAG" ]; then
    # Disable keep-awake mode
    rm -f "$KEEP_AWAKE_FLAG"
    
    # Restart xss-lock to re-enable automatic locking
    pkill -x xss-lock
    xss-lock --transfer-sleep-lock -- ~/.config/i3/lock-wrapper.sh &
    
    $NOTIFY_CMD "Keep-Awake Mode" "Disabled - Locking and suspend enabled" -i dialog-information
else
    # Enable keep-awake mode
    touch "$KEEP_AWAKE_FLAG"
    
    # Kill xss-lock to prevent automatic locking
    pkill -x xss-lock
    
    $NOTIFY_CMD "Keep-Awake Mode" "Enabled - Locking and suspend disabled" -i dialog-information
fi

# Update polybar (send IPC message to refresh)
polybar-msg cmd restart 2>/dev/null || true
