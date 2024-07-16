
#!/bin/bash

CONFIG_FILE=~/.config/i3/config
SED_CMD=sed

if [[ "$1" == "hdmi" ]]; then
    $SED_CMD -i 's/^workspace 6 output .*/workspace 6 output HDMI-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 7 output .*/workspace 7 output HDMI-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 8 output .*/workspace 8 output HDMI-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 9 output .*/workspace 9 output HDMI-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 10 output .*/workspace 10 output HDMI-1/' $CONFIG_FILE
elif [[ "$1" == "dp" ]]; then
    $SED_CMD -i 's/^workspace 6 output .*/workspace 6 output DP-2-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 7 output .*/workspace 7 output DP-2-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 8 output .*/workspace 8 output DP-2-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 9 output .*/workspace 9 output DP-2-1/' $CONFIG_FILE
    $SED_CMD -i 's/^workspace 10 output .*/workspace 10 output DP-2-1/' $CONFIG_FILE
fi

i3-msg reload
i3-msg restart
