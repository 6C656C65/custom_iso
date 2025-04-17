#!/bin/bash

FOLDER="./isofiles"

# Check if the folder exists
if [ -d "$FOLDER" ]; then
    echo "Deleting the $FOLDER folder"

    # Try deleting without sudo
    if rm -rf "$FOLDER" 2>/dev/null; then
        echo "The $FOLDER folder has been successfully deleted."
    else
        echo "Permission denied. Retrying with sudo..."
        sudo rm -rf "$FOLDER" && echo "The $FOLDER folder has been successfully deleted with sudo." || echo "Failed to delete $FOLDER even with sudo."
    fi
else
    echo "The $FOLDER folder does not exist."
fi
