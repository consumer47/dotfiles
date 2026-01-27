#!/bin/bash

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "rofi could not be found, please install it."
    exit 1
fi

# Define the display layout options as an associative array
declare -A options=(
    ["01. Single Internal"]="~/.screenlayout/layout_single_intern.sh"
    ["02. Home - Kensington Two Externals"]="~/.screenlayout/layout_home_kensington_two_externals.sh"
    ["03. Home - External Right"]="~/.screenlayout/layout_home_extRight.sh"
    ["04. Home - Left HDMI Right DP"]="~/.screenlayout/layout_home_left_hdmi_right_dp.sh"
    ["05. Work - External Right Docking"]="~/.screenlayout/layout_work_extRight_docking.sh"
    ["06. HDMI-1 Only"]="~/.screenlayout/HDMI-1-only.sh"
    ["07. 16:10 Aspect Ratio"]="~/.screenlayout/16by10.sh"
    ["08. 4:3 Aspect Ratio"]="~/.screenlayout/4by3.sh"
)

# Generate the options string for rofi
options_string=$(IFS=$'\n'; echo "${!options[*]}")

# Get the user choice through rofi
choice=$(echo -e "$options_string" | rofi -dmenu -i -p 'Display Layout' -no-sort )

# Check if the user made a choice
if [ -n "$choice" ]; then
    # Execute the layout script and update dynamic workspaces
    eval "${options[$choice]}" && ~/.config/i3/dynamic_workspaces.sh
else
    echo "No option selected."
fi


