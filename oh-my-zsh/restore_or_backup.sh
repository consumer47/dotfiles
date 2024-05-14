#!/bin/bash

# Define the Oh My Zsh custom directory
OHMYZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# The script is assumed to be run from the oh-my-zsh directory in the repo
REPO_DIR="$(pwd)"

# Function to ensure directory exists
ensure_dir() {
    if [ ! -d "$1" ]; then
        echo "Directory $1 does not exist. Creating..."
        mkdir -p "$1"
    fi
}

# Function to backup Oh My Zsh files to the repository
backup() {
    echo "Backing up Oh My Zsh files to the repository..."
    ensure_dir "$REPO_DIR/themes"
    ensure_dir "$REPO_DIR/plugins"
    cp -R "$OHMYZSH_CUSTOM/themes/"* "$REPO_DIR/themes/"
    cp -R "$OHMYZSH_CUSTOM/plugins/"* "$REPO_DIR/plugins/"
    cp "$HOME/.zshrc" "$REPO_DIR/.zshrc"
    echo "Backup complete."
}

# Function to restore Oh My Zsh files from the repository
restore() {
    echo "Restoring Oh My Zsh files from the repository..."
    ensure_dir "$OHMYZSH_CUSTOM/themes"
    ensure_dir "$OHMYZSH_CUSTOM/plugins"
    ln -sfn "$REPO_DIR/themes"/* "$OHMYZSH_CUSTOM/themes"
    ln -sfn "$REPO_DIR/plugins"/* "$OHMYZSH_CUSTOM/plugins"
    ln -sfn "$REPO_DIR/.zshrc" "$HOME/.zshrc"
    echo "Restore complete."
}

# Check the script argument to determine the mode
case "$1" in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
        ;;
esac
