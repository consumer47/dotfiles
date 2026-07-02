#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install essential packages
install_packages() {
    info "Updating package lists..."
    sudo apt-get update
    
    info "Installing essential packages..."
    sudo apt-get install -y \
        git \
        curl \
        build-essential \
        stow \
        zsh \
        neovim \
        tmux \
        fzf \
        zoxide \
        direnv
    
    info "Packages installed successfully"
}

# Clone dotfiles repository
clone_dotfiles() {
    if [ -d "$HOME/dotfiles" ]; then
        warn "Dotfiles directory already exists at $HOME/dotfiles"
        info "Skipping clone. Using existing dotfiles..."
        cd "$HOME/dotfiles"
    else
        info "Cloning dotfiles repository..."
        git clone --recurse-submodules https://github.com/consumer47/dotfiles.git ~/dotfiles
        cd ~/dotfiles
        info "Dotfiles cloned successfully"
    fi
}

# Deploy dotfiles using GNU Stow
deploy_dotfiles() {
    info "Deploying dotfiles with GNU Stow..."
    cd ~/dotfiles
    
    stow -v zsh || warn "Failed to stow zsh (may already be deployed)"
    stow -v nvim || warn "Failed to stow nvim (may already be deployed)"
    stow -v commonrc || warn "Failed to stow commonrc (may already be deployed)"
    stow -v claude || warn "Failed to stow claude (may already be deployed)"
    
    info "Dotfiles deployed successfully"
}

# Install zsh plugins
install_zsh_plugins() {
    info "Installing zsh plugins..."
    mkdir -p ~/.zsh/plugins
    
    # zsh-autosuggestions
    if [ -d "$HOME/.zsh/plugins/zsh-autosuggestions" ]; then
        warn "zsh-autosuggestions already installed"
    else
        info "Installing zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
    fi
    
    # zsh-syntax-highlighting
    if [ -d "$HOME/.zsh/plugins/zsh-syntax-highlighting" ]; then
        warn "zsh-syntax-highlighting already installed"
    else
        info "Installing zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
    fi
    
    # zsh-vi-man
    if [ -d "$HOME/.zsh/plugins/zsh-vi-man" ]; then
        warn "zsh-vi-man already installed"
    else
        info "Installing zsh-vi-man..."
        git clone --depth=1 https://github.com/TunaCuma/zsh-vi-man ~/.zsh/plugins/zsh-vi-man
    fi
    
    info "Zsh plugins installed successfully"
}

# Install powerlevel10k theme
install_powerlevel10k() {
    if [ -d "$HOME/powerlevel10k" ]; then
        warn "powerlevel10k already installed"
    else
        info "Installing powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
        info "powerlevel10k installed successfully"
    fi
}

# Install zoxide
install_zoxide() {
    if command -v zoxide &> /dev/null; then
        warn "zoxide already installed"
    else
        info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || {
            error "Failed to install zoxide"
            return 1
        }
        info "zoxide installed successfully"
    fi
}

# Install fzf
install_fzf() {
    if [ -d "$HOME/.fzf" ]; then
        warn "fzf already installed"
        if [ ! -f "$HOME/.fzf.zsh" ]; then
            info "Running fzf installer..."
            "$HOME/.fzf/install" --bin || warn "fzf installer failed (may already be configured)"
        fi
    else
        info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$HOME/.fzf/install" --bin || {
            error "Failed to run fzf installer"
            return 1
        }
        info "fzf installed successfully"
    fi
}

# Set zsh as default shell
set_zsh_default() {
    if [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
        info "zsh is already the default shell"
    else
        info "Setting zsh as default shell..."
        chsh -s $(which zsh) || {
            warn "Failed to change default shell. You may need to run: chsh -s $(which zsh)"
        }
        info "Default shell changed to zsh"
    fi
}

# Main function to orchestrate the setup
main() {
    info "Starting RPi first-time installation..."
    echo ""
    
    install_packages
    echo ""
    
    clone_dotfiles
    echo ""
    
    deploy_dotfiles
    echo ""
    
    install_zsh_plugins
    echo ""
    
    install_powerlevel10k
    echo ""
    
    install_zoxide
    echo ""
    
    install_fzf
    echo ""
    
    set_zsh_default
    echo ""
    
    info "=========================================="
    info "Installation complete!"
    info "=========================================="
    info "Next steps:"
    info "1. Log out and log back in (or run 'exec zsh') to start using zsh"
    info "2. Run 'p10k configure' to configure powerlevel10k theme (optional)"
    info "3. Your dotfiles are now deployed and ready to use"
    echo ""
}

# Run main function
main
