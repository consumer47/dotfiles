#!/bin/bash

CONFIG_FILE=~/.config/i3/config
INTERNAL_OUTPUT="eDP-1"

echo "Detecting active monitors..."
active_monitors_raw=$(xrandr --listactivemonitors)
active_outputs=$(echo "$active_monitors_raw" | awk '/^[[:space:]]*[0-9]+:/ {print $NF}')

echo "Active outputs:"
echo "$active_outputs"

internal_active=""
external_active=""
first_active=""

for output in $active_outputs; do
    if [[ -z "$first_active" ]]; then
        first_active="$output"
    fi

    if [[ "$output" == "$INTERNAL_OUTPUT" ]]; then
        internal_active="$output"
    elif [[ -z "$external_active" ]]; then
        external_active="$output"
    fi
done

if [[ -z "$internal_active" && -n "$first_active" ]]; then
    internal_active="$first_active"
fi

if [[ -z "$internal_active" ]]; then
    echo "No active monitors found. Exiting."
    exit 1
fi

echo "Internal target: $internal_active"
if [[ -n "$external_active" ]]; then
    echo "External target: $external_active"
else
    echo "No external target found; using single monitor mode."
fi

echo "Updating workspace-to-output lines in i3 config..."

if [[ -n "$external_active" ]]; then
    for ws in {1..5}; do
        sed -i "s/^workspace $ws output .*/workspace $ws output $internal_active/" "$CONFIG_FILE"
    done
    for ws in {6..10}; do
        sed -i "s/^workspace $ws output .*/workspace $ws output $external_active/" "$CONFIG_FILE"
    done
else
    for ws in {1..10}; do
        sed -i "s/^workspace $ws output .*/workspace $ws output $internal_active/" "$CONFIG_FILE"
    done
fi

echo "Reloading i3 config..."
i3-msg reload > /dev/null

# Wait for reload to settle before workspace routing.
sleep 0.2

if [[ -n "$external_active" ]]; then
    for ws in {1..5}; do
        i3-msg "workspace number $ws; move workspace to output $internal_active" > /dev/null
    done
    for ws in {6..10}; do
        i3-msg "workspace number $ws; move workspace to output $external_active" > /dev/null
    done
else
    for ws in {1..10}; do
        i3-msg "workspace number $ws; move workspace to output $internal_active" > /dev/null
    done
fi

# Return focus to workspace 1 to keep behavior predictable.
i3-msg "workspace number 1" > /dev/null

echo "Workspace routing complete."
