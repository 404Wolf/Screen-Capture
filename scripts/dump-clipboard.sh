set -euo pipefail

# Get clipboard content and clean the file:// prefix
TO_DUMP=$(wl-paste | sed 's#^file://##') || {
    notify-send "Error" "No valid file URL in clipboard"
    exit 1
}

# Verify the source file exists
if [ ! -f "$TO_DUMP" ]; then
    notify-send "Error" "Source file not found: $TO_DUMP"
    exit 1
fi

# Get the destination directory from user
OUTPATH=$(zenity --file-selection --directory --save --title "Choose where to save the file") || {
    notify-send "Cancelled" "File save cancelled"
    exit 1
}

# Create output filename and path
OUT_FILENAME=$(basename "$TO_DUMP")
OUTPATH="$OUTPATH/$OUT_FILENAME"

# Check if file already exists
if [ -f "$OUTPATH" ]; then
    zenity --question --text="File already exists. Overwrite?" || {
        notify-send "Cancelled" "File save cancelled"
        exit 1
    }
fi

# Copy the file
if cp "$TO_DUMP" "$OUTPATH"; then
    notify-send "Success" "File saved to $OUTPATH"
else
    notify-send "Error" "Failed to save file"
    exit 1
fi
