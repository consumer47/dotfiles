#!/bin/bash

# Install essential packages
install_packages() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y git stow zsh neovim tmux fzf
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew update
        brew install git stow zsh neovim
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    git clone --recurse-submodules https://github.com/consumer47/dotfiles.git ~/dotfiles
    cd ~/dotfiles
}

# Deploy dotfiles using GNU Stow
deploy_dotfiles() {
    cd ~/dotfiles
    stow -v zsh
    stow -v nvim
}

# Main function to orchestrate the setup
main() {
    install_packages
    clone_dotfiles
    deploy_dotfiles
    echo "Installation complete!"
}

main

