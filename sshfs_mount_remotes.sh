#!/bin/bash
# exampole command: 
# sshfs dietpi@10.20.32.88:/home/dietpi/workbench/rgb-led-pi /home/dennis/remote-rtb-parking-led-pi
# Define an associative array for project configurations
declare -A PROJECTS
declare -A MOUNT_POINTS

# Project 'led'
PROJECTS['led,work']="dietpi@10.20.32.88:/home/dietpi/workbench/rgb-led-pi"
PROJECTS['led,home']="dietpi@rtb-parking-led-pi:/home/dietpi/workbench/rgb-led-pi"
MOUNT_POINTS['led']="/home/dennis/remote-rtb-parking-led-pi"

# Project 'frontradar-pi'
# Add the respective user, IP or hostname, and remote path for the 'frontradar-pi' project
# PROJECTS['frontradar-pi,work']="user@work-ip:/remote/path"
# PROJECTS['frontradar-pi,home']="user@home-hostname:/remote/path"
# MOUNT_POINTS['frontradar-pi']="/home/dennis/remote-frontradar-pi"

# Function to display help
show_help() {
    echo "Usage: $0 [project-name]"
    echo "Example: $0 led"
    echo "Available projects:"
    for project in "${!MOUNT_POINTS[@]}"; do
        echo " - $project"
    done
    exit 1
}

# Function to mount using SSHFS
mount_sshfs() {
    local remote_path=$1
    local mount_point=$2
    sshfs "$remote_path" "$mount_point" -o reconnect
    if [ $? -eq 0 ]; then
        echo "Successfully mounted $remote_path at $mount_point"
        return 0
    else
        echo "Failed to mount $remote_path at $mount_point"
        return 1
    fi
}

# Check for help argument
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
fi

# Check if project name is provided
if [ -z "$1" ]; then
    echo "Error: No project name provided."
    show_help
fi

# Get the project name from the first argument
PROJECT_NAME="$1"

# Check if the project name is valid
if [ -z "${MOUNT_POINTS[$PROJECT_NAME]}" ]; then
    echo "Error: Unknown project '$PROJECT_NAME'."
    show_help
fi

# Attempt to mount each configured setup for the project
for LOCATION in work home; do
    PROJECT_KEY="$PROJECT_NAME,$LOCATION"
    if [ -n "${PROJECTS[$PROJECT_KEY]}" ]; then
        if mount_sshfs "${PROJECTS[$PROJECT_KEY]}" "${MOUNT_POINTS[$PROJECT_NAME]}"; then
            exit 0
        fi
    else
        echo "Configuration for '$PROJECT_KEY' not found."
    fi
done

echo "All mount attempts failed for project '$PROJECT_NAME'."
exit 1
