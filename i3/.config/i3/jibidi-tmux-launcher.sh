#!/bin/bash
# Launcher script for jibidi tmux session
# Used by i3 shortcut (super shift g) to launch jibidi without a prompt
# Creates a new session and runs jibidi interactively

# Create a unique session name
SESSION_NAME="jibidi-$(date +%H%M%S)"

# Create new tmux session and run jibidi directly
# Run jibidi in zsh with interactive mode to ensure functions are loaded
# This avoids script execution issues that might cause hanging
tmux new-session -d -s "$SESSION_NAME" "zsh -ic 'jibidi'"

# Attach to the session
exec tmux attach -t "$SESSION_NAME"

