#!/bin/bash

CONFIG_FILE=~/.config/i3/config
SED_CMD=sed

# Map the workspace variables to the correct numbers based on your i3 config
ws6="6"
ws7="7"
ws8="8"
ws9="9"
ws10="10"

if [[ "$1" == "hdmi" ]]; then
    $SED_CMD -i "s/^workspace $ws6 output .*/workspace $ws6 output HDMI-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws7 output .*/workspace $ws7 output HDMI-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws8 output .*/workspace $ws8 output HDMI-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws9 output .*/workspace $ws9 output HDMI-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws10 output .*/workspace $ws10 output HDMI-1/" $CONFIG_FILE
elif [[ "$1" == "dp" ]]; then
    $SED_CMD -i "s/^workspace $ws6 output .*/workspace $ws6 output DP-2-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws7 output .*/workspace $ws7 output DP-2-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws8 output .*/workspace $ws8 output DP-2-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws9 output .*/workspace $ws9 output DP-2-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws10 output .*/workspace $ws10 output DP-2-1/" $CONFIG_FILE
else
    $SED_CMD -i "s/^workspace $ws6 output .*/workspace $ws6 output eDP-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws7 output .*/workspace $ws7 output eDP-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws8 output .*/workspace $ws8 output eDP-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws9 output .*/workspace $ws9 output eDP-1/" $CONFIG_FILE
    $SED_CMD -i "s/^workspace $ws10 output .*/workspace $ws10 output eDP-1/" $CONFIG_FILE
fi

i3-msg reload
i3-msg restart
