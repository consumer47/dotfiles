#!/bin/bash

# Check if the argument is passed
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-workspace>"
    exit 1
fi

# Get the folder name from the full path
SESSION_NAME=$(basename "$1")

# Attempt to attach to the existing session or create a new one
if zellij attach "$SESSION_NAME"; then
    echo "Attached to existing session: $SESSION_NAME"
else
    echo "Creating new session: $SESSION_NAME"
    zellij --session "$SESSION_NAME"
fi