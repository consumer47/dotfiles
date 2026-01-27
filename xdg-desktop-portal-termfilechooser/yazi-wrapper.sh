#!/usr/bin/env sh
# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
#
# For more information about input/output arguments read `xdg-desktop-portal-termfilechooser(5)`

set -ex

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

cmd="/home/dennis/.cargo/bin/yazi"
termcmd="${TERMCMD:-/usr/bin/gnome-terminal --title='termfilechooser' --}"

if [ "$save" = "1" ]; then
    # save a file
    set -- --chooser-file="$out" "$path"
elif [ "$directory" = "1" ]; then
    # upload files from a directory
    set -- --chooser-file="$out" --cwd-file="$out" "$path"
elif [ "$multiple" = "1" ]; then
    # upload multiple files
    set -- --chooser-file="$out" "$path"
else
    # upload only 1 file
    set -- --chooser-file="$out" "$path"
fi

# Ensure the chooser file exists before launching yazi
touch "$out"

command="$termcmd $cmd"
for arg in "$@"; do
    # escape double quotes
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    # escape spaces
    command="$command \"$escaped\""
done

# Run the command and wait for terminal to close
if command -v xterm >/dev/null 2>&1; then
    # xterm waits properly
    xterm -title "File Chooser" -e "$cmd" "$@"
else
    # Fallback: run directly without terminal (for debugging)
    "$cmd" "$@"
fi

# Ensure the chooser file still exists after yazi exits
# If yazi didn't create it (user cancelled), create an empty one
sleep 0.1
touch "$out"
# Debug: log the file contents
echo "DEBUG: Chooser file contents: $(cat "$out" 2>/dev/null || echo 'empty')" >&2
