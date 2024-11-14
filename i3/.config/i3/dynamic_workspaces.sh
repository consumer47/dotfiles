#!/bin/bash

CONFIG_FILE=~/.config/i3/config

# Detect connected outputs and display the full output for debugging
connected_outputs=$(xrandr --listactivemonitors)
echo "connected_outputs (full output):"
echo "$connected_outputs"
echo "Extracting monitor identifiers..."

# Extract the last column (monitor identifier) from each line that contains a monitor listing
monitor_ids=$(echo "$connected_outputs" | awk '/^[[:space:]]*[0-9]+:/ {print $NF}')

# Display extracted monitor identifiers for debugging
echo "Extracted monitor identifiers:"
echo "$monitor_ids"

# Set default outputs
output1=""
output2=""

# Assign outputs based on connection order, displaying assignments for debugging
index=1
for output in $monitor_ids; do
    if [[ $index -eq 1 ]]; then
        output1="$output"
        echo "Assigned to output1: $output1"
    elif [[ $index -eq 2 ]]; then
        output2="$output"
        echo "Assigned to output2: $output2"
    fi
    index=$((index + 1))
done

# Update i3 configuration based on detected outputs, with debug messages
echo "Updating i3 configuration..."

if [[ -n "$output2" ]]; then
    echo "Detected dual monitor setup."
    for ws in {1..5}; do
        echo "Assigning workspace $ws to $output1"
        sed -i "s/^workspace $ws output .*/workspace $ws output $output1/" "$CONFIG_FILE"
    done
    for ws in {6..10}; do
        echo "Assigning workspace $ws to $output2"
        sed -i "s/^workspace $ws output .*/workspace $ws output $output2/" "$CONFIG_FILE"
    done
else
    echo "Detected single monitor setup or only one monitor could be assigned."
    for ws in {1..10}; do
        echo "Assigning workspace $ws to $output1"
        sed -i "s/^workspace $ws output .*/workspace $ws output $output1/" "$CONFIG_FILE"
    done
fi

echo "Reloading and restarting i3..."
i3-msg reload
i3-msg restart

echo "Script finished."
