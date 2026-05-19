#!/bin/bash

# Script to sync VSCode configuration to Cursor
# This prevents Cursor from overwriting your carefully crafted VSCode keybindings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
VSCODE_USER_DIR="$HOME/.config/Code/User"
CURSOR_USER_DIR="$HOME/.config/Cursor/User"

# Files to sync
FILES_TO_SYNC=(
    "keybindings.json"
    "settings.json"
)

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

# Function to backup a file
backup_file() {
    local file_path="$1"
    local backup_path="${file_path}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file_path" ]; then
        cp "$file_path" "$backup_path"
        print_success "Backed up $file_path to $backup_path"
    fi
}

# Function to sync a file from VSCode to Cursor
sync_file() {
    local filename="$1"
    local vscode_file="$VSCODE_USER_DIR/$filename"
    local cursor_file="$CURSOR_USER_DIR/$filename"
    
    print_status "Syncing $filename..."
    
    # Check if VSCode file exists
    if [ ! -f "$vscode_file" ]; then
        print_warning "VSCode $filename not found, skipping..."
        return 1
    fi
    
    # Create Cursor config directory if it doesn't exist
    mkdir -p "$CURSOR_USER_DIR"
    
    # Backup existing Cursor file if it exists
    if [ -f "$cursor_file" ]; then
        backup_file "$cursor_file"
    fi
    
    # Copy VSCode file to Cursor
    cp "$vscode_file" "$cursor_file"
    print_success "Synced $filename from VSCode to Cursor"
}

# Main function
main() {
    print_status "Starting VSCode to Cursor configuration sync..."
    print_status "VSCode config: $VSCODE_USER_DIR"
    print_status "Cursor config: $CURSOR_USER_DIR"
    
    # Check if VSCode config directory exists
    if [ ! -d "$VSCODE_USER_DIR" ]; then
        print_error "VSCode configuration directory not found: $VSCODE_USER_DIR"
        exit 1
    fi
    
    # Sync each file
    local synced_count=0
    for file in "${FILES_TO_SYNC[@]}"; do
        if sync_file "$file"; then
            ((synced_count++))
        fi
    done
    
    print_success "Sync completed! Synced $synced_count files."
    print_status "Your VSCode keybindings and settings have been copied to Cursor."
    print_warning "Remember to restart Cursor for changes to take effect."
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Sync VSCode configuration files to Cursor to prevent overwriting."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --dry-run  Show what would be synced without making changes"
    echo ""
    echo "Files synced:"
    for file in "${FILES_TO_SYNC[@]}"; do
        echo "  - $file"
    done
}

# Dry run function
dry_run() {
    print_status "DRY RUN - No files will be modified"
    print_status "Would sync the following files from VSCode to Cursor:"
    
    for file in "${FILES_TO_SYNC[@]}"; do
        local vscode_file="$VSCODE_USER_DIR/$file"
        local cursor_file="$CURSOR_USER_DIR/$file"
        
        if [ -f "$vscode_file" ]; then
            echo "  ✓ $file ($(du -h "$vscode_file" | cut -f1))"
            if [ -f "$cursor_file" ]; then
                echo "    → Would backup existing Cursor $file"
            fi
        else
            echo "  ✗ $file (not found in VSCode)"
        fi
    done
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -d|--dry-run)
        dry_run
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

