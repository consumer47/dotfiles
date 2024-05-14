#!/bin/bash

# The path to the i3 config directory in the user's home
I3_CONFIG_DIR="$HOME/.config/i3"
I3_CONFIG_FILE="$I3_CONFIG_DIR/config"

# Determine the hostname
HOSTNAME=$(hostname)

# Define the config file names
CONFIG_WORK="config.work"
CONFIG_PRIVATE="config.private"

# Check if the i3 config directory exists
if [ ! -d "$I3_CONFIG_DIR" ]; then
  echo "Creating i3 config directory at $I3_CONFIG_DIR"
  mkdir -p "$I3_CONFIG_DIR"
fi

# Create a symlink for the main i3 config file
ln -sf "$(pwd)/i3/config" "$I3_CONFIG_FILE"

# Conditional symlinking based on the hostname
case "$HOSTNAME" in
   dennis-ThinkPad-P15s-Gen-2i)
    ln -sf "$(pwd)/i3/$CONFIG_WORK" "$I3_CONFIG_DIR/$CONFIG_WORK"
    echo "#include $I3_CONFIG_DIR/$CONFIG_WORK" >> "$I3_CONFIG_FILE"
    ;;
  *private-hostname*)
    ln -sf "$(pwd)/i3/$CONFIG_PRIVATE" "$I3_CONFIG_DIR/$CONFIG_PRIVATE"
    echo "#include $I3_CONFIG_DIR/$CONFIG_PRIVATE" >> "$I3_CONFIG_FILE"
    ;;
esac

echo "Symlink created for i3 config."
