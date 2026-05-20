#!/bin/bash

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "rofi could not be found, please install it."
    exit 1
fi

# Define the settings options as an associative array
declare -A options=(
    ["01. Display Layouts"]="/home/dennis/dotfiles/rofi/display_menu.sh"
    ["02. Display (GUI)"]="arandr"
    ["03. Dynamic Workspaces"]="~/.config/i3/dynamic_workspaces.sh"
    ["04. Dynamic Workspaces Auto Setup"]="~/.config/i3/dynamic_workspaces_auto.sh"
    ["05. Network"]="nm-connection-editor"
    ["06. Network_TUI"]="gnome-terminal -- nmtui"
    ["07. Network_NVIm"]="gnome-terminal -- sudo nvim /etc/NetworkManager/system-connections/"
    ["08. Bluetooth"]="blueman-manager"
    ["09. Audio"]="gnome-terminal -- pulsemixer"
    ["10. SpotifyTUI"]="gnome-terminal -- spt"
    ["11. Audio_old"]="pavucontrol"
#    ["12. Display (CLI)"]="gnome-terminal -- xrandr & read"
    ["12. File Manager"]="gnome-terminal -- ranger"
    ["13. System Monitor"]="gnome-terminal -- htop"
    ["14. SSH Site Toggle"]="~/.config/i3/ssh-site-toggle.sh"
)

# Generate the options string for rofi
options_string=$(IFS=$'\n'; echo "${!options[*]}")

# Get the user choice through rofi
choice=$(echo -e "$options_string" | rofi -dmenu -i -p 'Settings' -no-sort )

# Check if the user made a choice
if [ -n "$choice" ]; then
    # Execute the command associated with the choice
    eval "${options[$choice]}" || echo "Failed to execute ${options[$choice]}"
else
    echo "No option selected."
fi
