#!/bin/bash

# The path to the i3 config directory in the user's home
I3_CONFIG_DIR="$HOME/.config/i3"

# Check if the i3 config directory exists
if [ ! -d "$I3_CONFIG_DIR" ]; then
  echo "Creating i3 config directory at $I3_CONFIG_DIR"
  mkdir -p "$I3_CONFIG_DIR"
fi

# Create a symlink for the i3 config file
ln -sf "$(pwd)/i3/config" "$I3_CONFIG_DIR/config"

echo "Symlink created for i3 config."
