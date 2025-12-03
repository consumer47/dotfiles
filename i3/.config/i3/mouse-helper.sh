#!/bin/bash
# Helper script for i3 mouse mode operations

case "$1" in
    # Jump movement (half screen)
    jump-left)
        W=$(xdotool getdisplaygeometry | awk '{print $1}')
        xdotool mousemove_relative -- -$((W/2)) 0
        ;;
    jump-right)
        W=$(xdotool getdisplaygeometry | awk '{print $1}')
        xdotool mousemove_relative -- $((W/2)) 0
        ;;
    jump-up)
        H=$(xdotool getdisplaygeometry | awk '{print $2}')
        xdotool mousemove_relative -- 0 -$((H/2))
        ;;
    jump-down)
        H=$(xdotool getdisplaygeometry | awk '{print $2}')
        xdotool mousemove_relative -- 0 $((H/2))
        ;;
    # Position jumps
    window-center)
        INFO=$(xdotool getactivewindow getwindowgeometry)
        X=$(echo "$INFO" | grep "Position:" | awk '{print $2}' | cut -d',' -f1)
        Y=$(echo "$INFO" | grep "Position:" | awk '{print $2}' | cut -d',' -f2)
        W=$(echo "$INFO" | grep "Geometry:" | awk '{print $2}' | cut -d'x' -f1)
        H=$(echo "$INFO" | grep "Geometry:" | awk '{print $2}' | cut -d'x' -f2)
        xdotool mousemove $((X+W/2)) $((Y+H/2))
        ;;
    screen-center)
        read W H <<< $(xdotool getdisplaygeometry)
        xdotool mousemove $((W/2)) $((H/2))
        ;;
    *)
        echo "Usage: $0 {jump-left|jump-right|jump-up|jump-down|window-center|screen-center}"
        exit 1
        ;;
esac

