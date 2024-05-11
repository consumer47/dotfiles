#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define backup directory relative to the script location
BACKUP_DIR="$SCRIPT_DIR/vscode"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup extensions list
code --list-extensions > "$BACKUP_DIR/vscode-extensions-list.txt"

# Backup settings.json, keybindings.json, and snippets
cp "$HOME/.config/Code/User/settings.json" "$BACKUP_DIR/settings.json" 2>/dev/null || :
cp "$HOME/.config/Code/User/keybindings.json" "$BACKUP_DIR/keybindings.json" 2>/dev/null || :
cp -r "$HOME/.config/Code/User/snippets" "$BACKUP_DIR/snippets" 2>/dev/null || :

echo "VSCode backup is complete. Find the backup at: $BACKUP_DIR"
