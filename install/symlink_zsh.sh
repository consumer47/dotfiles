#!/bin/bash

# symlink_zsh.sh
# This script ensures that the target directories and files exist before creating a symbolic link for the .zshrc file.

# Define the relative path to the .zshrc file in the dotfiles repository
# Assuming the .zshrc file is located at the root of your dotfiles structure
ZSHRC_RELATIVE_PATH="../zsh/.zshrc"

# Define the absolute path to the user's home directory
HOME_DIR="$HOME"

# Define the target path for the .zshrc file in the home directory
ZSHRC_TARGET="$HOME_DIR/.zshrc"

# Ensure the target directory exists (in this case, the home directory should exist, but this is just an example)
if [ ! -d "$HOME_DIR" ]; then
    echo "Creating home directory at $HOME_DIR"
    mkdir -p "$HOME_DIR"
fi

# Check if the source .zshrc file exists
if [ ! -f "$ZSHRC_RELATIVE_PATH" ]; then
    echo "The source .zshrc file does not exist. Creating a blank .zshrc at $ZSHRC_RELATIVE_PATH"
    mkdir -p "$(dirname $ZSHRC_RELATIVE_PATH)" # Ensure the parent directory exists
    touch "$ZSHRC_RELATIVE_PATH"
fi

# Check if the .zshrc file already exists in the home directory and back it up if it does
if [ -f "$ZSHRC_TARGET" ]; then
    echo "Backing up existing .zshrc to .zshrc.backup"
    mv "$ZSHRC_TARGET" "${ZSHRC_TARGET}.backup"
fi

# Create the symbolic link
ln -s "$(realpath $ZSHRC_RELATIVE_PATH)" "$ZSHRC_TARGET"

# Verify the operation
if [ -L "$ZSHRC_TARGET" ]; then
    echo "Symbolic link created for .zshrc"
else
    echo "Failed to create symbolic link for .zshrc"
    exit 1
fi
