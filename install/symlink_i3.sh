#!/bin/bash

echo "dont forget to add home hostname!"
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
  echo "Creating i3 config directory at $I3_CONFIG_DIR..."
  mkdir -p "$I3_CONFIG_DIR" || { echo "Failed to create i3 config directory."; exit 1; }
fi

echo "Linking the main i3 config file..."
# Create a symlink for the main i3 config file
if ln -sf "$(pwd)/i3/config" "$I3_CONFIG_FILE"; then
  echo "Main i3 config linked successfully."
else
  echo "Failed to link the main i3 config."
  exit 1
fi

# Conditional symlinking based on the hostname
echo "Setting up machine-specific i3 config..."
case "$HOSTNAME" in
  dennis-ThinkPad-P15s-Gen-2i)
    if ln -sf "$(pwd)/i3/$CONFIG_WORK" "$I3_CONFIG_DIR/$CONFIG_WORK"; then
      echo "Work config linked successfully."
      echo "#include $I3_CONFIG_DIR/$CONFIG_WORK" >> "$I3_CONFIG_FILE" || { echo "Failed to write include directive to main config."; exit 1; }
    else
      echo "Failed to link work config."
      exit 1
    fi
    ;;
  *private-hostname*)
    if ln -sf "$(pwd)/i3/$CONFIG_PRIVATE" "$I3_CONFIG_DIR/$CONFIG_PRIVATE"; then
      echo "Private config linked successfully."
      echo "#include $I3_CONFIG_DIR/$CONFIG_PRIVATE" >> "$I3_CONFIG_FILE" || { echo "Failed to write include directive to main config."; exit 1; }
    else
      echo "Failed to link private config."
      exit 1
    fi
    ;;
  *)
    echo "No matching hostname found for specific configurations. Only the main config has been linked."
    ;;
esac

echo "i3 config setup complete."
