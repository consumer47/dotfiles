#!/bin/bash

# ThinkPad Fan Control Script
# Usage: ./fan_control.sh [level|auto|status|max]
#   level: Set fan to specific level (0-7, where 7 is maximum)
#   auto: Set fan back to automatic mode
#   status: Show current fan status
#   max: Set fan to maximum speed (level 7)

FAN_CTRL="/proc/acpi/ibm/fan"
FAN_MODULE="/sys/module/thinkpad_acpi/parameters/fan_control"

# Check if running as root for fan control
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Error: This script needs sudo privileges to control the fan."
        echo "Usage: sudo $0 [level|auto|status|max]"
        exit 1
    fi
}

# Check if fan control is enabled
check_fan_control() {
    if [ -f "$FAN_MODULE" ]; then
        local fan_ctrl_status=$(cat "$FAN_MODULE" 2>/dev/null)
        if [ "$fan_ctrl_status" = "N" ]; then
            echo "ERROR: Fan control is not enabled!"
            echo ""
            echo "To enable fan control, you need to add it to kernel parameters:"
            echo "  1. Edit /etc/default/grub"
            echo "  2. Add 'thinkpad_acpi.fan_control=1' to GRUB_CMDLINE_LINUX_DEFAULT"
            echo "  3. Run: sudo update-grub"
            echo "  4. Reboot"
            echo ""
            echo "Example:"
            echo "  GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash thinkpad_acpi.fan_control=1\""
            echo ""
            exit 1
        fi
    fi
}

# Show current fan status
show_status() {
    if [ -f "$FAN_CTRL" ]; then
        echo "=== Fan Status ==="
        cat "$FAN_CTRL"
        echo ""
        echo "=== Current Temperatures ==="
        if [ -f "/proc/acpi/ibm/thermal" ]; then
            cat /proc/acpi/ibm/thermal
        fi
    else
        echo "Error: Fan control interface not found at $FAN_CTRL"
        exit 1
    fi
}

# Set fan level
set_fan_level() {
    local level=$1
    if [ -z "$level" ]; then
        echo "Error: Please specify a fan level (0-7)"
        echo "Levels: 0=off, 1-7=speed levels (7=max)"
        exit 1
    fi
    
    if ! [[ "$level" =~ ^[0-7]$ ]]; then
        echo "Error: Fan level must be between 0 and 7"
        exit 1
    fi
    
    check_fan_control
    
    if echo "level $level" > "$FAN_CTRL" 2>/dev/null; then
        sleep 1
        echo "Fan set to level $level"
        show_status
    else
        echo "Error: Failed to set fan level. Make sure fan control is enabled."
        exit 1
    fi
}

# Set fan to auto mode
set_fan_auto() {
    check_fan_control
    
    if echo "level auto" > "$FAN_CTRL" 2>/dev/null; then
        sleep 1
        echo "Fan set to automatic mode"
        show_status
    else
        echo "Error: Failed to set fan to auto mode."
        exit 1
    fi
}

# Set fan to maximum speed
set_fan_max() {
    check_fan_control
    
    if echo "level 7" > "$FAN_CTRL" 2>/dev/null; then
        sleep 1
        echo "Fan set to maximum speed (level 7)"
        show_status
    else
        echo "Error: Failed to set fan to maximum speed."
        exit 1
    fi
}

# Main script logic
case "${1:-status}" in
    status)
        show_status
        ;;
    auto)
        check_root
        set_fan_auto
        ;;
    max)
        check_root
        set_fan_max
        ;;
    [0-7])
        check_root
        set_fan_level "$1"
        ;;
    *)
        echo "ThinkPad Fan Control"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status          Show current fan status (no sudo needed)"
        echo "  auto            Set fan to automatic mode"
        echo "  max             Set fan to maximum speed (level 7)"
        echo "  0-7             Set fan to specific level (0=off, 7=max)"
        echo ""
        echo "Examples:"
        echo "  $0 status       # Check current status"
        echo "  sudo $0 max     # Set to maximum speed"
        echo "  sudo $0 5       # Set to level 5"
        echo "  sudo $0 auto    # Return to automatic mode"
        exit 1
        ;;
esac

