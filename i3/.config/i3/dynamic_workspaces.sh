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

# Wait a moment for i3 to settle after restart
sleep 0.5

# Get the currently focused workspace before moving things around
workspaces_json=$(i3-msg -t get_workspaces)
current_workspace=$(echo "$workspaces_json" | grep -o '"focused":true[^}]*"num":[0-9]*' | grep -o '"num":[0-9]*' | grep -o '[0-9]*' | head -1)

echo "Moving workspaces to their assigned outputs..."

# Function to move workspaces to their assigned output
move_workspaces_to_output() {
    local target_output=$1
    shift
    local workspaces=("$@")
    
    for ws in "${workspaces[@]}"; do
        # Check if workspace exists in workspace list
        ws_info=$(echo "$workspaces_json" | grep "\"num\":$ws" | head -1)
        
        if [[ -n "$ws_info" ]]; then
            # Extract current output
            current_output=$(echo "$ws_info" | grep -o '"output":"[^"]*"' | cut -d'"' -f4)
            
            # If workspace is on wrong output, check if it has windows and move it
            if [[ "$current_output" != "$target_output" ]]; then
                # Check if workspace has windows by checking if it has a name different from its number
                # or if it's visible (which indicates it has content)
                ws_name=$(echo "$ws_info" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                is_visible=$(echo "$ws_info" | grep -o '"visible":true')
                
                # Workspace has windows if it's visible or has a non-default name
                # (empty workspaces typically just have their number as the name)
                has_windows=""
                if [[ -n "$is_visible" ]]; then
                    has_windows="yes"
                elif [[ -n "$ws_name" ]] && [[ "$ws_name" != "$ws" ]]; then
                    # Name differs from number, likely has windows
                    has_windows="yes"
                fi
                
                # If workspace has windows, switch to it to move it to the correct output
                if [[ -n "$has_windows" ]]; then
                    echo "Moving workspace $ws from $current_output to $target_output"
                    i3-msg "workspace number $ws" > /dev/null 2>&1
                    sleep 0.1
                fi
            fi
        fi
    done
}

# Move workspaces based on detected setup
if [[ -n "$output2" ]]; then
    # Dual monitor: workspaces 1-5 to output1, 6-10 to output2
    move_workspaces_to_output "$output1" {1..5}
    move_workspaces_to_output "$output2" {6..10}
else
    # Single monitor: all workspaces to output1
    move_workspaces_to_output "$output1" {1..10}
fi

# Switch back to the previously focused workspace
if [[ -n "$current_workspace" ]]; then
    i3-msg "workspace number $current_workspace" > /dev/null 2>&1
fi

echo "Script finished."
