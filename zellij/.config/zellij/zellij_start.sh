#!/bin/bash

# Usage:
#   zellij_start.sh [--new] <path-to-workspace>

LAYOUT_PATH="/home/dennis/dotfiles/zellij/.config/zellij/layouts/sidebar.kdl"

# Parse optional --new flag
NEW_SESSION=""
if [ "$1" = "--new" ]; then
    NEW_SESSION=1
    shift
fi

# Check if the argument is passed
if [ -z "$1" ]; then
    echo "Usage: $0 [--new] <path-to-workspace>"
    exit 1
fi

# Get the folder name from the full path
SESSION_NAME=$(basename "$1")

if [ -n "$NEW_SESSION" ]; then
    # Create a unique session name to avoid attaching to an existing one
    SESSION_NAME="${SESSION_NAME}-$(date +%H%M%S)"
    echo "Creating new session: $SESSION_NAME"
    exec zellij --session "$SESSION_NAME" --layout "$LAYOUT_PATH"
fi

# Attempt to attach to the existing session or create a new one
if zellij attach "$SESSION_NAME"; then
    echo "Attached to existing session: $SESSION_NAME"
else
    echo "Creating new session: $SESSION_NAME"
    zellij --session "$SESSION_NAME" --layout "$LAYOUT_PATH"
fi