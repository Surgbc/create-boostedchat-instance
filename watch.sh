#!/bin/bash

which inotifywait || apt install inotify-tools -y
# Check if inotifywait is installed
command -v inotifywait >/dev/null 2>&1 || { echo >&2 "inotifywait is required but it's not installed. Aborting."; exit 1; }

# Define the file to watch
file_to_watch="/root/update"

if [ -f "/root/watch.sh" ]; then
    touch "$file_to_watch"
fi


# Function to execute when file changes
on_file_change() {
    echo "File $file_to_watch has been modified. Running update scripts"
    ## pull updates
    /bin/bash /root/pullUpdatedImages.sh
}

# Watch for changes in the file
while true; do
    inotifywait -e modify "$file_to_watch"
    on_file_change
done