#!/bin/bash

# Define the dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

# Function to ask for system type and install dependencies accordingly
install_dependencies() {
  echo "Which system are you on?"
  echo "1) Debian-based (Ubuntu, Debian)"
  echo "2) Red Hat-based (Fedora, CentOS)"
  echo "3) macOS (Homebrew)"
  read -p "Select an option (1-3): " os_choice

  local dependencies=()

  # Ask for each tool
  read -p "Install tmux? (y/N): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] && dependencies+=("tmux")

  read -p "Install Vim? (y/N): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] && dependencies+=("vim")

  read -p "Install Git? (y/N): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] && dependencies+=("git")

  read -p "Install Zsh? (y/N): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] && dependencies+=("zsh")

  # Check if the system is likely to have a GUI before installing i3
  if [ "$(uname -s)" != "Linux" ] || [ -z "$DISPLAY" ]; then
    echo "i3 window manager installation skipped due to non-GUI system."
  else
    read -p "Install i3 window manager? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && dependencies+=("i3")
  fi

  if [ ${#dependencies[@]} -eq 0 ]; then
    echo "No tools selected for installation."
    return
  fi

  echo "Installing selected dependencies..."

  case $os_choice in
    1)
      sudo apt update
      for package in "${dependencies[@]}"; do
        sudo apt install -y "$package"
      done
      ;;
    2)
      sudo dnf check-update
      for package in "${dependencies[@]}"; do
        sudo dnf install -y "$package"
      done
      ;;
    3)
      for package in "${dependencies[@]}"; do
        brew install "$package"
      done
      ;;
    *)
      echo "Invalid option selected. Skipping dependency installation."
      ;;
  esac
}

# Function to create a symbolic link and backup the original file
link_file() {
  local src=$1 dst=$2

  # Check if the file already exists and is not a symlink
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    # Prompt user for action
    read -p "File $dst already exists. Do you want to back it up? (Y/n) " -n 1 -r
    echo    # Move to a new line

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Backup the existing file before linking
      local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
      echo "Backing up $dst to $backup"
      mv "$dst" "$backup"
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Skipping backup of $dst"
    else
      echo "Invalid input. Skipping backup of $dst"
    fi
  fi

  # Create the symbolic link
  ln -sf "$src" "$dst"
}

# Function to link dotfiles
link_dotfiles() {
  echo "Linking dotfiles..."

  # List of files to link with the expected dot prefix
  declare -A files_to_link=(
    ["$DOTFILES_DIR/tmux/.tmux.conf"]="$HOME/.tmux.conf"
    ["$DOTFILES_DIR/vim/.vimrc"]="$HOME/.vimrc"
    ["$DOTFILES_DIR/bash/.bashrc"]="$HOME/.bashrc"
    ["$DOTFILES_DIR/zsh/.zshrc"]="$HOME/.zshrc"
  )

  # i3 config typically doesn't have a dot prefix
  # Check if the i3 config directory exists before attempting to link
  if [ -d "$HOME/.config/i3" ]; then
    files_to_link+=(
      ["$DOTFILES_DIR/i3/config"]="$HOME/.config/i3/config"
    )
  else
    echo "i3 config directory does not exist, skipping i3 config linking..."
  fi

  for src in "${!files_to_link[@]}"; do
    dst=${files_to_link[$src]}
    link_file "$src" "$dst"
  done
}

main() {
  read -p "Do you want to install dependencies? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_dependencies
  else
    echo "Skipping dependency installation."
  fi

  link_dotfiles
  echo "Dotfiles installation complete."
}

# Start the installation process
main
