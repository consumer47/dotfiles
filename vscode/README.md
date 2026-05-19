# VSCode and Cursor Configuration Management

This directory contains tools to manage VSCode and Cursor configurations and prevent Cursor from overwriting your carefully crafted VSCode keybindings.

## The Problem

Cursor IDE (which is based on VSCode) can sometimes overwrite your existing VSCode keybindings and settings when you switch between the two editors. This happens because:

1. Both editors store configurations in separate directories
2. Cursor may import from VSCode on first run
3. Changes in one editor don't automatically sync to the other

## Solutions

### Quick Fix: Sync VSCode to Cursor

If you want to immediately restore your VSCode keybindings to Cursor:

```bash
./sync_vscode_to_cursor.sh
```

This script will:
- Backup any existing Cursor configurations
- Copy your VSCode keybindings and settings to Cursor
- Preserve your carefully configured shortcuts

### Long-term Solution: Centralized Configuration Management

For a permanent solution that keeps both editors in sync:

```bash
./setup_vscode_configs.sh
```

This script will:
1. Copy your existing configurations to your dotfiles
2. Create symlinks so both editors use the same config files
3. Prevent future overwrites by centralizing configuration management

## Configuration Files Managed

- `keybindings.json` - Custom keyboard shortcuts
- `settings.json` - Editor preferences and settings

## Manual Backup

Before making changes, you can manually backup your configurations:

```bash
# Backup VSCode config
cp ~/.config/Code/User/keybindings.json ~/.config/Code/User/keybindings.json.backup
cp ~/.config/Code/User/settings.json ~/.config/Code/User/settings.json.backup

# Backup Cursor config
cp ~/.config/Cursor/User/keybindings.json ~/.config/Cursor/User/keybindings.json.backup
cp ~/.config/Cursor/User/settings.json ~/.config/Cursor/User/settings.json.backup
```

## Configuration Locations

- **VSCode**: `~/.config/Code/User/`
- **Cursor**: `~/.config/Cursor/User/`
- **Dotfiles**: `~/dotfiles/vscode/`

## Tips

1. **Use VSCode as Master**: If you have extensively customized VSCode, use it as the master configuration
2. **Regular Syncing**: Run the sync script after making changes to your master configuration
3. **Version Control**: Keep your configurations in git to track changes
4. **Test Changes**: Make small changes and test them before doing a full sync

## Troubleshooting

### Keybindings Not Working

1. Check if the configuration files exist in the correct locations
2. Restart the editor after syncing
3. Check for JSON syntax errors in configuration files

### Cursor Overwrites Again

If Cursor continues to overwrite your settings:
1. Use the centralized configuration management (symlinks)
2. Check that Cursor doesn't have auto-sync enabled with cloud services
3. Ensure file permissions are correct

### Restore from Backup

If something goes wrong, restore from backup:

```bash
# Find your backup files
ls ~/.config/Cursor/User/*.backup.*

# Restore (replace with your backup filename)
cp ~/.config/Cursor/User/keybindings.json.backup.20240101_120000 ~/.config/Cursor/User/keybindings.json
```

