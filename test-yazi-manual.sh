#!/bin/bash
# Test script to debug yazi file chooser

echo "Testing yazi manually with chooser file..."

# Create a temporary chooser file
CHOOSER_FILE="/tmp/manual-test-chooser"
rm -f "$CHOOSER_FILE"

echo "Running: /home/dennis/.cargo/bin/yazi --chooser-file=$CHOOSER_FILE /home/dennis"

# Try running yazi directly
/home/dennis/.cargo/bin/yazi --chooser-file="$CHOOSER_FILE" /home/dennis

echo "Yazi exit code: $?"

if [ -f "$CHOOSER_FILE" ]; then
    echo "Chooser file was created:"
    cat "$CHOOSER_FILE"
else
    echo "Chooser file was NOT created"
fi

rm -f "$CHOOSER_FILE" 