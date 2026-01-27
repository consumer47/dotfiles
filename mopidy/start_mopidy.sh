#!/bin/bash
# Start Mopidy music server with Spotify and Iris web interface
# Access at: http://localhost:6680/iris/

# Fix GStreamer plugin path (snap interference)
export GST_PLUGIN_SCANNER=/usr/lib/x86_64-linux-gnu/gstreamer1.0/gstreamer-1.0/gst-plugin-scanner
export GST_PLUGIN_SYSTEM_PATH=/usr/lib/x86_64-linux-gnu/gstreamer-1.0
unset GST_PLUGIN_PATH

mopidy

