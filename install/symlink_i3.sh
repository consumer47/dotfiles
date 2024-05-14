#!/bin/bash

# Define the directory where the i3 configs are located
I3_CONFIG_DIR="$HOME/.config/i3"

# Define the base and machine-specific config file names
BASE_CONFIG="config"
MACHINE_SPECIFIC_CONFIG="config.machine"
WORK_CONFIG="config.work"
PRIVATE_CONFIG="config.private"

# Determine the hostname of the system
HOSTNAME=$(hostname)

# Define the symlink path for the machine-specific config
SYMLINK_PATH="$I3_CONFIG_DIR/$MACHINE_SPECIFIC_CONFIG"

# Remove the existing symlink if it exists
rm -f "$SYMLINK_PATH"

# Create a new symlink based on the hostname
if [[ "$HOSTNAME" == "dennis-ThinkPad-P15s-Gen-2i" ]]; then
  # Link to the work configuration
  ln -s "$I3_CONFIG_DIR/$WORK_CONFIG" "$SYMLINK_PATH"
  echo "Symlinked to work configuration."
else
  # Link to the private configuration
  ln -s "$I3_CONFIG_DIR/$PRIVATE_CONFIG" "$SYMLINK_PATH"
  echo "Symlinked to private configuration."
fi

