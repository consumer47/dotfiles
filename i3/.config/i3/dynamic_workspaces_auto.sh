#!/bin/bash

# Auto-setup dynamic workspaces with screen detection
# eDP-1 is internal and always present (left)
# Any other connected screen is external (right, when connected)

INTERNAL_SCREEN="eDP-1"

echo "Detecting connected screens..."

# Get all connected screens (excluding disconnected ones)
connected_screens=$(xrandr --query | grep " connected" | awk '{print $1}')

# Find external screen (any connected screen that is not eDP-1)
EXTERNAL_SCREEN=""
for screen in $connected_screens; do
    if [[ "$screen" != "$INTERNAL_SCREEN" ]]; then
        EXTERNAL_SCREEN="$screen"
        break
    fi
done

# Check if external screen was found
external_connected=""
if [[ -n "$EXTERNAL_SCREEN" ]]; then
    external_connected="yes"
fi

if [[ -n "$external_connected" ]]; then
    echo "External screen ${EXTERNAL_SCREEN} detected. Setting up dual monitor layout..."
    echo "Internal screen (${INTERNAL_SCREEN}) will be on the left"
    echo "External screen (${EXTERNAL_SCREEN}) will be on the right"
    
    # Get the resolution of the external screen
    external_resolution=$(xrandr --query | grep "^${EXTERNAL_SCREEN} connected" | grep -oE '[0-9]+x[0-9]+' | head -1)
    
    if [[ -z "$external_resolution" ]]; then
        # Try to get preferred mode if no current mode is set
        external_resolution=$(xrandr --query | grep -A 1 "^${EXTERNAL_SCREEN} connected" | grep -oE '[0-9]+x[0-9]+' | head -1)
    fi
    
    if [[ -z "$external_resolution" ]]; then
        # Default resolution if we can't detect it
        external_resolution="2560x1440"
        echo "Using default resolution ${external_resolution} for external screen"
    else
        echo "Detected external screen resolution: ${external_resolution}"
    fi
    
    # Get internal screen resolution
    internal_resolution=$(xrandr --query | grep "^${INTERNAL_SCREEN} connected" | grep -oE '[0-9]+x[0-9]+' | head -1)
    
    if [[ -z "$internal_resolution" ]]; then
        internal_resolution="1920x1080"
        echo "Using default resolution ${internal_resolution} for internal screen"
    else
        echo "Detected internal screen resolution: ${internal_resolution}"
    fi
    
    # Extract width from internal resolution for positioning
    internal_width=$(echo "$internal_resolution" | cut -d'x' -f1)
    
    # Get all available outputs to turn off the ones we're not using
    all_outputs=$(xrandr --query | grep -E "^[A-Za-z0-9-]+" | awk '{print $1}')
    
    # Build xrandr command: set internal and external, turn off all others
    xrandr_cmd="xrandr --output ${INTERNAL_SCREEN} --primary --mode ${internal_resolution} --pos 0x0 --rotate normal"
    xrandr_cmd="${xrandr_cmd} --output ${EXTERNAL_SCREEN} --mode ${external_resolution} --pos ${internal_width}x0 --rotate normal"
    
    # Turn off all other outputs
    for output in $all_outputs; do
        if [[ "$output" != "$INTERNAL_SCREEN" ]] && [[ "$output" != "$EXTERNAL_SCREEN" ]]; then
            xrandr_cmd="${xrandr_cmd} --output ${output} --off"
        fi
    done
    
    # Execute the xrandr command
    eval "$xrandr_cmd"
    
    echo "Screen layout configured successfully"
else
    echo "No external screen detected. Using internal screen only..."
    
    # Get internal screen resolution
    internal_resolution=$(xrandr --query | grep "^${INTERNAL_SCREEN} connected" | grep -oE '[0-9]+x[0-9]+' | head -1)
    
    if [[ -z "$internal_resolution" ]]; then
        internal_resolution="1920x1080"
        echo "Using default resolution ${internal_resolution} for internal screen"
    else
        echo "Detected internal screen resolution: ${internal_resolution}"
    fi
    
    # Get all available outputs to turn off the ones we're not using
    all_outputs=$(xrandr --query | grep -E "^[A-Za-z0-9-]+" | awk '{print $1}')
    
    # Build xrandr command: set internal only, turn off all others
    xrandr_cmd="xrandr --output ${INTERNAL_SCREEN} --primary --mode ${internal_resolution} --pos 0x0 --rotate normal"
    
    # Turn off all other outputs
    for output in $all_outputs; do
        if [[ "$output" != "$INTERNAL_SCREEN" ]]; then
            xrandr_cmd="${xrandr_cmd} --output ${output} --off"
        fi
    done
    
    # Execute the xrandr command
    eval "$xrandr_cmd"
    
    echo "Screen layout configured successfully"
fi

# Wait a moment for xrandr to apply
sleep 0.5

# Now run the dynamic workspaces script
echo ""
echo "Running dynamic workspaces setup..."
~/.config/i3/dynamic_workspaces.sh

echo "Dynamic workspaces auto-setup complete!"
