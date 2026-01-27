#!/bin/bash

# Automatic fan control based on CPU temperature
# This script monitors CPU temperature and adjusts fan speed accordingly
# Usage: sudo ./fan_auto_temp.sh [--daemon]

FAN_CTRL="/proc/acpi/ibm/fan"
CPU_TEMP="/sys/devices/platform/coretemp.0/hwmon/hwmon8/temp1_input"

# Temperature thresholds (in millidegrees Celsius, so multiply by 1000)
TEMP_LOW=50000   # 50°C - use level 2
TEMP_MED=65000   # 65°C - use level 4
TEMP_HIGH=80000  # 80°C - use level 6
TEMP_CRITICAL=90000  # 90°C - use level 7 (max)

# Enable fan control
enable_fan_control() {
    if [ -f "/sys/module/thinkpad_acpi/parameters/fan_control" ] && \
       [ "$(cat /sys/module/thinkpad_acpi/parameters/fan_control)" = "N" ]; then
        modprobe thinkpad_acpi fan_control=1 2>/dev/null || true
        sleep 1
    fi
}

# Get CPU temperature in millidegrees
get_cpu_temp() {
    if [ -f "$CPU_TEMP" ]; then
        cat "$CPU_TEMP"
    else
        # Fallback to thermal zone
        if [ -f "/sys/class/thermal/thermal_zone8/temp" ]; then
            cat /sys/class/thermal/thermal_zone8/temp
        else
            echo "0"
        fi
    fi
}

# Set fan level based on temperature
set_fan_by_temp() {
    local temp=$1
    local level
    
    if [ "$temp" -ge "$TEMP_CRITICAL" ]; then
        level=7
    elif [ "$temp" -ge "$TEMP_HIGH" ]; then
        level=6
    elif [ "$temp" -ge "$TEMP_MED" ]; then
        level=4
    elif [ "$temp" -ge "$TEMP_LOW" ]; then
        level=2
    else
        level=1
    fi
    
    echo "level $level" > "$FAN_CTRL" 2>/dev/null
    echo "$level"
}

# Main monitoring loop
monitor_loop() {
    enable_fan_control
    
    echo "Starting automatic fan control based on CPU temperature..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    while true; do
        temp=$(get_cpu_temp)
        temp_c=$((temp / 1000))
        level=$(set_fan_by_temp "$temp")
        
        printf "\rCPU: %d°C | Fan: Level %d" "$temp_c" "$level"
        
        sleep 5
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script needs sudo privileges to control the fan."
    echo "Usage: sudo $0 [--daemon]"
    exit 1
fi

if [ "$1" = "--daemon" ]; then
    monitor_loop &
    echo $! > /tmp/fan_auto_temp.pid
    echo "Fan control daemon started (PID: $(cat /tmp/fan_auto_temp.pid))"
    echo "To stop: sudo kill \$(cat /tmp/fan_auto_temp.pid)"
else
    monitor_loop
fi





