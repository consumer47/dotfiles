#!/bin/bash

# Define the dotfiles directory
DOTFILES_DIR=$HOME/dotfiles

# Function to create a symbolic link
link_file () {
  ln -sf "$1" "$2"
}

# Tmux configuration
link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Vim configuration
link_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Bash configuration
link_file "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"

# Zsh configuration
link_file "$DOTILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# i3 Window Manager configuration
# Assuming the i3 config is in the .config directory
link_file "$DOTFILES_DIR/i3/config" "$HOME/.config/i3/config"

echo "Dotfiles have been linked."
