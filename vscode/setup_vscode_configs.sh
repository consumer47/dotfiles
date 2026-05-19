#!/bin/bash

# Script to set up VSCode configuration management in dotfiles
# This creates symlinks from your dotfiles to VSCode/Cursor config directories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
DOTFILES_VSCODE_DIR="$HOME/dotfiles/vscode"
VSCODE_USER_DIR="$HOME/.config/Code/User"
CURSOR_USER_DIR="$HOME/.config/Cursor/User"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup and copy config files to dotfiles
setup_config_in_dotfiles() {
    local config_name="$1"  # "vscode" or "cursor"
    local source_dir="$2"
    local target_dir="$DOTFILES_VSCODE_DIR/$config_name"
    
    print_status "Setting up $config_name configuration in dotfiles..."
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Files to manage
    local files=("keybindings.json" "settings.json")
    
    for file in "${files[@]}"; do
        local source_file="$source_dir/$file"
        local target_file="$target_dir/$file"
        
        if [ -f "$source_file" ]; then
            # If target doesn't exist, copy from source
            if [ ! -f "$target_file" ]; then
                cp "$source_file" "$target_file"
                print_success "Copied $file to dotfiles/$config_name/"
            else
                print_warning "$config_name/$file already exists in dotfiles"
            fi
        else
            print_warning "$config_name $file not found at $source_file"
        fi
    done
}

# Function to create symlinks from dotfiles to config directories
create_symlinks() {
    local config_name="$1"
    local target_dir="$2"
    local source_dir="$DOTFILES_VSCODE_DIR/$config_name"
    
    print_status "Creating symlinks for $config_name..."
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    local files=("keybindings.json" "settings.json")
    
    for file in "${files[@]}"; do
        local source_file="$source_dir/$file"
        local target_file="$target_dir/$file"
        
        if [ -f "$source_file" ]; then
            # Backup existing file if it exists and is not a symlink
            if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
                mv "$target_file" "$target_file.backup.$(date +%Y%m%d_%H%M%S)"
                print_warning "Backed up existing $target_file"
            fi
            
            # Remove existing symlink or file
            rm -f "$target_file"
            
            # Create symlink
            ln -s "$source_file" "$target_file"
            print_success "Created symlink: $target_file -> $source_file"
        else
            print_warning "Source file not found: $source_file"
        fi
    done
}

# Main setup function
main() {
    print_status "Setting up VSCode/Cursor configuration management..."
    
    # Step 1: Copy existing configs to dotfiles if they don't exist there
    if [ -d "$VSCODE_USER_DIR" ]; then
        setup_config_in_dotfiles "vscode" "$VSCODE_USER_DIR"
    fi
    
    if [ -d "$CURSOR_USER_DIR" ]; then
        setup_config_in_dotfiles "cursor" "$CURSOR_USER_DIR"
    fi
    
    # Step 2: Ask user which configuration to use as the master
    echo ""
    print_status "Which configuration would you like to use as the master?"
    echo "1) VSCode (recommended - use your existing VSCode config for both)"
    echo "2) Cursor (use Cursor config for both)"
    echo "3) Keep separate (maintain different configs for each)"
    echo "4) Skip symlink creation"
    
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1)
            print_status "Using VSCode configuration as master for both VSCode and Cursor..."
            create_symlinks "vscode" "$VSCODE_USER_DIR"
            create_symlinks "vscode" "$CURSOR_USER_DIR"
            print_success "Both VSCode and Cursor now use the same configuration from dotfiles/vscode/"
            ;;
        2)
            print_status "Using Cursor configuration as master for both VSCode and Cursor..."
            create_symlinks "cursor" "$VSCODE_USER_DIR"
            create_symlinks "cursor" "$CURSOR_USER_DIR"
            print_success "Both VSCode and Cursor now use the same configuration from dotfiles/cursor/"
            ;;
        3)
            print_status "Setting up separate configurations..."
            create_symlinks "vscode" "$VSCODE_USER_DIR"
            create_symlinks "cursor" "$CURSOR_USER_DIR"
            print_success "VSCode and Cursor use separate configurations from dotfiles/"
            ;;
        4)
            print_status "Skipping symlink creation. Configurations copied to dotfiles only."
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    echo ""
    print_success "Setup complete!"
    print_status "Your configurations are now managed in:"
    echo "  - $DOTFILES_VSCODE_DIR/vscode/"
    echo "  - $DOTFILES_VSCODE_DIR/cursor/"
    print_warning "Don't forget to commit these changes to your dotfiles repo!"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Set up VSCode/Cursor configuration management in dotfiles."
    echo "This script will:"
    echo "  1. Copy existing configs to your dotfiles directory"
    echo "  2. Create symlinks to manage configurations centrally"
    echo "  3. Prevent Cursor from overwriting your VSCode settings"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

