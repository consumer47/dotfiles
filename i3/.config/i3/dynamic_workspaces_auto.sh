#!/bin/bash

# Auto-setup dynamic workspaces with screen detection
# eDP-1 is internal and always present (left)
# DP-2-2-1 is external (right, when connected)

INTERNAL_SCREEN="eDP-1"
EXTERNAL_SCREEN="DP-2-2-1"

echo "Detecting connected screens..."

# Check if external screen is connected
external_connected=$(xrandr --query | grep -c "^${EXTERNAL_SCREEN} connected")

if [[ $external_connected -gt 0 ]]; then
    echo "External screen ${EXTERNAL_SCREEN} detected. Setting up dual monitor layout..."
    echo "Internal screen (${INTERNAL_SCREEN}) will be on the left"
    echo "External screen (${EXTERNAL_SCREEN}) will be on the right"
    
    # Get the resolution of the external screen
    external_resolution=$(xrandr --query | grep "^${EXTERNAL_SCREEN} connected" | grep -oE '[0-9]+x[0-9]+' | head -1)
    
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
    
    # Set up xrandr: eDP-1 on left, DP-2-2-1 on right
    xrandr --output "${INTERNAL_SCREEN}" --primary --mode "${internal_resolution}" --pos 0x0 --rotate normal \
           --output "${EXTERNAL_SCREEN}" --mode "${external_resolution}" --pos "${internal_width}x0" --rotate normal \
           --output HDMI-1 --off \
           --output DP-1 --off \
           --output DP-2 --off \
           --output DP-3 --off \
           --output DP-4 --off \
           --output DP-2-1 --off \
           --output DP-2-2 --off \
           --output DP-2-3 --off
    
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
    
    # Set up xrandr: eDP-1 only, turn off all other outputs
    xrandr --output "${INTERNAL_SCREEN}" --primary --mode "${internal_resolution}" --pos 0x0 --rotate normal \
           --output HDMI-1 --off \
           --output DP-1 --off \
           --output DP-2 --off \
           --output DP-3 --off \
           --output DP-4 --off \
           --output DP-2-1 --off \
           --output DP-2-2 --off \
           --output DP-2-2-1 --off \
           --output DP-2-3 --off
    
    echo "Screen layout configured successfully"
fi

# Wait a moment for xrandr to apply
sleep 0.5

# Now run the dynamic workspaces script
echo ""
echo "Running dynamic workspaces setup..."
~/.config/i3/dynamic_workspaces.sh

echo "Dynamic workspaces auto-setup complete!"
