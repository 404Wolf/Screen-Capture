set -o nounset
set -o pipefail

SCREENSHOT_DELAY=${SCREENSHOT_DELAY:-0}

if [ -z "$SCREENSHOT_DELAY" ]; then
    SCREENSHOT_DELAY=0
fi

LOCK_FILE="/tmp/screenshot.lock"
RUNNING_PID=$(cat "$LOCK_FILE" 2>/dev/null)

if [ -n "$RUNNING_PID" ]; then
    kill -9 -"$RUNNING_PID" 2>/dev/null
    sleep 0.5
    rm -f "$LOCK_FILE"

    LAST_OUTPUT_FILE=$(cat "/tmp/screenshot-tools-last_output_file" 2>/dev/null)
    if [ -n "$LAST_OUTPUT_FILE" ] && [ -f "$LAST_OUTPUT_FILE" ]; then
        notify-send "Recording stopped" "File copied to clipboard"
    fi
    exit 0
else
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <image|video|gif>"
        exit 1
    fi
fi
echo $$ > "$LOCK_FILE"

OUTPUT_DIR=~/Screenshots
mkdir -p "$OUTPUT_DIR"

REGION=$(slurp)
if [ -z "$REGION" ]; then
    echo "No region selected. Exiting."
    rm -f "$LOCK_FILE"
    exit 1
fi

set_output() {
    FILENAME="$(uuidgen).$1"
    OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"
    wl-copy --type text/uri-list "file://$OUTPUT_FILE"
}

case "$1" in
    "image")
        set_output png
        sleep "$SCREENSHOT_DELAY"
        grim -g "$REGION" "$OUTPUT_FILE"
        notify-send "Screenshot captured" "Image saved to $OUTPUT_FILE"
        rm -f "$LOCK_FILE"
        ;;
    "video")
        set_output mp4
        echo "$OUTPUT_FILE" > "/tmp/screenshot-tools-last_output_file"
        wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" &
        notify-send "Recording started" "Run script again to stop"
        ;;
    "gif")
        set_output gif
        echo "$OUTPUT_FILE" > "/tmp/screenshot-tools-last_output_file"
        wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" &
        notify-send "Recording started" "Run script again to stop"
        ;;
esac
