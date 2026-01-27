#!/bin/bash

echo "=== Testing yazi chooser file behavior ==="

CHOOSER_FILE="/tmp/debug-chooser-test"
rm -f "$CHOOSER_FILE"

echo "1. Before running yazi:"
ls -la "$CHOOSER_FILE" 2>/dev/null || echo "File does not exist (expected)"

echo "2. Running yazi with chooser file..."
echo "   IMPORTANT: You need to SELECT a file and press ENTER to create the chooser file"
echo "   Just quitting with 'q' won't create the file!"
echo ""

# Run yazi and wait for it to finish
/home/dennis/.cargo/bin/yazi --chooser-file="$CHOOSER_FILE" /home/dennis

echo "3. After running yazi:"
if [ -f "$CHOOSER_FILE" ]; then
    echo "SUCCESS! Chooser file was created:"
    cat "$CHOOSER_FILE"
else
    echo "FAILED: Chooser file was not created"
    echo "This means you either quit without selecting, or there's another issue"
fi

rm -f "$CHOOSER_FILE" 