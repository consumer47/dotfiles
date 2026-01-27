#!/usr/bin/env bash

# Lock Wrapper Script
# Checks keep-awake flag before locking

KEEP_AWAKE_FLAG="/tmp/keep-awake.flag"
I3LOCK_SCRIPT="$HOME/.config/i3lock/lock"

if [ -f "$KEEP_AWAKE_FLAG" ]; then
    notify-send "Lock Blocked" "Keep-awake mode is active. Disable it to lock the screen." -i dialog-warning
    exit 0
fi

# Check if we're being called by xss-lock (needs --nofork)
# xss-lock will be the parent process
PARENT_CMD=$(ps -o comm= -p $PPID 2>/dev/null)
NEED_NOFORK=false
if [ "$PARENT_CMD" = "xss-lock" ] || echo "$*" | grep -q -- "--nofork"; then
    NEED_NOFORK=true
fi

# Execute the actual lock
if [ -f "$I3LOCK_SCRIPT" ] && [ "$NEED_NOFORK" = "false" ]; then
    # Call the lock script normally (for manual locks)
    exec "$I3LOCK_SCRIPT"
else
    # Call i3lock directly with the lock script's configuration
    # This is needed when called by xss-lock (needs --nofork)
    NOFORK_ARG=""
    if [ "$NEED_NOFORK" = "true" ]; then
        NOFORK_ARG="--nofork"
    fi
    
    exec i3lock \
        --insidever-color='#ffffff22' \
        --ringver-color='#00564dE6' \
        --insidewrong-color='#ffffff22' \
        --ringwrong-color='#880000bb' \
        --inside-color='#00000000' \
        --ring-color='#00897bE6' \
        --line-color='#00000000' \
        --separator-color='#00897bE6' \
        --verif-color='#00897bE6' \
        --wrong-color='#00897bE6' \
        --time-color='#00897bE6' \
        --date-color='#00897bE6' \
        --layout-color='#00897bE6' \
        --keyhl-color='#880000bb' \
        --bshl-color='#880000bb' \
        --screen 1 \
        --blur 9 \
        --clock \
        --indicator \
        --time-str="%H:%M:%S" \
        --date-str="%A, %Y-%m-%d" \
        --keylayout 1 \
        $NOFORK_ARG
fi
