#!/bin/bash

# Define the settings options
options="Network\nBluetooth\nAudio\nDisplay\nFile Manager\nSystem Monitor"

# Get the user choice through rofi
choice=$(echo -e "$options" | rofi -dmenu -i -p 'Settings')

# Execute the appropriate command based on user choice
case "$choice" in
    Network) nm-applet ;;
    Bluetooth) blueman-manager ;;
    Audio) pavucontrol ;;
    Display) arandr ;;
    "File Manager") ranger ;;
    "System Monitor") gnome-system-monitor ;;
    *) exit 1 ;;
esac
