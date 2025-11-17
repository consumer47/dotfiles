#!/bin/bash
# Launcher script for jibidi tmux session
# Used by i3 shortcut (super shift g) to launch jibidi without a prompt
# Creates a new session and runs jibidi interactively

# Create a unique session name
SESSION_NAME="jibidi-$(date +%H%M%S)"

# Create a temporary script that runs jibidi without a prompt
TMP_SCRIPT=$(mktemp /tmp/jibidi-interactive-XXXXXX.sh)
cat > "$TMP_SCRIPT" << 'SCRIPT_EOF'
#!/bin/bash
# Source zshrc to get jibidi function
source ~/.zshrc 2>/dev/null || true
# Run jibidi interactively (no prompt, user can type)
jibidi
SCRIPT_EOF
chmod +x "$TMP_SCRIPT"

# Create new tmux session and run jibidi
tmux new-session -d -s "$SESSION_NAME" "$TMP_SCRIPT"

# Attach to the session
exec tmux attach -t "$SESSION_NAME"

