#!/bin/bash

# Script to enable ThinkPad fan control via kernel parameters
# This adds 'thinkpad_acpi.fan_control=1' to GRUB configuration

GRUB_FILE="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script needs sudo privileges."
    echo "Usage: sudo $0"
    exit 1
fi

# Check if already enabled
if grep -q "thinkpad_acpi.fan_control=1" "$GRUB_FILE" 2>/dev/null; then
    echo "Fan control is already enabled in GRUB configuration."
    echo "You may need to reboot for changes to take effect."
    exit 0
fi

# Backup original file
if [ -f "$GRUB_FILE" ]; then
    cp "$GRUB_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# Add fan_control parameter
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_FILE"; then
    # Modify existing line
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 thinkpad_acpi.fan_control=1"/' "$GRUB_FILE"
    # Handle case without quotes
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=\([^"].*\)$/GRUB_CMDLINE_LINUX_DEFAULT="\1 thinkpad_acpi.fan_control=1"/' "$GRUB_FILE"
else
    # Add new line
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="thinkpad_acpi.fan_control=1"' >> "$GRUB_FILE"
fi

echo "Fan control parameter added to GRUB configuration."
echo ""
echo "Next steps:"
echo "  1. Run: sudo update-grub"
echo "  2. Reboot your system"
echo ""
echo "After reboot, you can use:"
echo "  sudo ~/dotfiles/shortcuts/fan_control.sh max"
echo "  sudo ~/dotfiles/shortcuts/fan_control.sh 7"
echo ""
read -p "Do you want to run 'update-grub' now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    update-grub
    echo ""
    echo "GRUB updated. Please reboot for fan control to be enabled."
fi





