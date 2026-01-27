#!/bin/bash

# Script to capture images from pi-cam every 10 seconds
# Usage: ./pi-cam-capture.sh [output_filename]

PI_HOST="pi@billard-test-pi"
OUTPUT_FILE="${1:-pi-cam-test.jpg}"
TEMP_FILE="/tmp/pi-cam-capture.jpg"
INTERVAL=10

echo "Starting pi-cam capture loop..."
echo "Capturing every ${INTERVAL} seconds to: ${OUTPUT_FILE}"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] Capturing image..."
    
    # Capture image on pi
    if ssh "${PI_HOST}" "libcamera-jpeg -o ${TEMP_FILE} --timeout 2000 --nopreview >/dev/null 2>&1"; then
        # Copy image to local repo
        if scp "${PI_HOST}:${TEMP_FILE}" "${OUTPUT_FILE}" >/dev/null 2>&1; then
            SIZE=$(ls -lh "${OUTPUT_FILE}" | awk '{print $5}')
            echo "[${TIMESTAMP}] Image captured successfully (${SIZE})"
        else
            echo "[${TIMESTAMP}] Error: Failed to copy image"
        fi
    else
        echo "[${TIMESTAMP}] Error: Failed to capture image"
    fi
    
    sleep "${INTERVAL}"
done
