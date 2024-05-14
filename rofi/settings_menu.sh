#!/bin/bash

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "rofi could not be found, please install it."
    exit 1
fi

# Define the settings options as an associative array
declare -A options=(
    ["Network"]="nm-applet"
    ["Bluetooth"]="blueman-manager"
    ["Audio"]="pavucontrol"
    ["Display (GUI)"]="arandr"
#    ["Display (CLI)"]="gnome-terminal -- xrandr & read"
    ["File Manager"]="gnome-terminal -- ranger"
    ["System Monitor"]="gnome-terminal -- htop"
)

# Generate the options string for rofi
options_string=$(IFS=$'\n'; echo "${!options[*]}")

# Get the user choice through rofi
choice=$(echo -e "$options_string" | rofi -dmenu -i -p 'Settings' )

# Check if the user made a choice
if [ -n "$choice" ]; then
    # Execute the command associated with the choice
    ${options[$choice]} || echo "Failed to execute ${options[$choice]}"
else
    echo "No option selected."
fi
