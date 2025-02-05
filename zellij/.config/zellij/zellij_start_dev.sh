#!/bin/bash

# Echo all the arguments passed to the script
echo "Arguments: $@"

# Keep the terminal open and wait for user input
while true; do
    read -p "Enter something (or type 'exit' to quit): " user_input
    if [[ "$user_input" == "exit" ]]; then
        echo "Exiting..."
        break
    else
        echo "You entered: $user_input"
    fi
done