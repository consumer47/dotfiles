#!/bin/bash

DEVICE_IP="192.168.178.171"
DEVICE_PORT="5555"

# Function to check if ADB is connected
is_device_connected() {
    adb devices | grep -q "$DEVICE_IP:$DEVICE_PORT"
}

# Background loop to ensure persistent connection
while true; do
    if ! is_device_connected; then
        echo "🔄 Attempting ADB connection..."
        adb connect "$DEVICE_IP:$DEVICE_PORT"
        sleep 2
    fi
    sleep 10  # Check every 10 seconds
done
