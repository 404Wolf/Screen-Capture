set -o nounset
set -o pipefail

SCREENSHOT_DELAY=${SCREENSHOT_DELAY:-0}

if [ -z "$SCREENSHOT_DELAY" ]; then
    SCREENSHOT_DELAY=0
fi

PID_THIS="/tmp/screenshot.lock"
PID_WF_RECORDER="/tmp/screenshot-recorder.pid"
RUNNING_PID=$(cat "$PID_THIS" 2>/dev/null)

if [ -n "$RUNNING_PID" ]; then
    # Get the actual wf-recorder PID
    RECORDER_PID=$(cat "$PID_WF_RECORDER" 2>/dev/null)

    if [ -n "$RECORDER_PID" ] && kill -0 "$RECORDER_PID" 2>/dev/null; then
        # Send SIGINT to properly stop recording
        kill -SIGINT "$RECORDER_PID" 2>/dev/null

        # Wait for the process to terminate with a timeout
        MAX_WAIT=10  # Maximum wait time in seconds
        WAITED=0
        while kill -0 "$RECORDER_PID" 2>/dev/null && [ $WAITED -lt $MAX_WAIT ]; do
            sleep 0.5
            WAITED=$((WAITED + 1))
        done

        # If process is still running after timeout, force kill it
        if kill -0 "$RECORDER_PID" 2>/dev/null; then
            kill -9 "$RECORDER_PID" 2>/dev/null
        fi
    fi

    # Get the output file
    LAST_OUTPUT_FILE=$(cat "/tmp/screenshot-tools-last_output_file" 2>/dev/null)
    LAST_OUTPUT_TYPE=$(cat "/tmp/screenshot-tools-last_output_type" 2>/dev/null)

    # For GIF, we need to convert the mp4 to gif after recording
    if [ "$LAST_OUTPUT_TYPE" = "gif" ] && [ -n "$LAST_OUTPUT_FILE" ] && [ -f "$LAST_OUTPUT_FILE" ]; then
        GIF_FILE="${LAST_OUTPUT_FILE%.mp4}.gif"

        # Run conversion in the background to prevent freezing
        (
            # Convert using ffmpeg
            ffmpeg -i "$LAST_OUTPUT_FILE" -vf "fps=15,scale=800:-1:flags=lanczos" -c:v gif "$GIF_FILE"

            # Remove the temporary mp4 file
            rm -f "$LAST_OUTPUT_FILE"

            # Copy the GIF file to clipboard when done
            wl-copy --type text/uri-list "file://$GIF_FILE"

            # Notify when conversion is complete
            notify-send "GIF Conversion Complete" "GIF saved to $GIF_FILE and copied to clipboard"
        ) &

        notify-send "Recording stopped" "Converting to GIF in background..."
    else
        if [ -n "$LAST_OUTPUT_FILE" ] && [ -f "$LAST_OUTPUT_FILE" ]; then
            notify-send "Recording stopped" "File copied to clipboard"
        fi
    fi

    # Clean up
    rm -f "$PID_THIS" "$PID_WF_RECORDER" "/tmp/screenshot-tools-last_output_type"
    exit 0
else
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <image|video|gif>"
        exit 1
    fi
fi
echo $$ > "$PID_THIS"

OUTPUT_DIR=~/Screenshots
mkdir -p "$OUTPUT_DIR"

REGION=$(slurp)
if [ -z "$REGION" ]; then
    echo "No region selected. Exiting."
    rm -f "$PID_THIS"
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
        rm -f "$PID_THIS"
        ;;
    "video")
        set_output mp4
        echo "$OUTPUT_FILE" > "/tmp/screenshot-tools-last_output_file"
        echo "video" > "/tmp/screenshot-tools-last_output_type"

        # Start wf-recorder and store its PID
        wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" &
        echo $! > "$PID_WF_RECORDER"

        notify-send "Recording started" "Run script again to stop"
        ;;
    "gif")
        # For GIF, we'll record as MP4 first, then convert
        TEMP_FILENAME="$(uuidgen).mp4"
        OUTPUT_FILE="$OUTPUT_DIR/$TEMP_FILENAME"
        echo "$OUTPUT_FILE" > "/tmp/screenshot-tools-last_output_file"
        echo "gif" > "/tmp/screenshot-tools-last_output_type"

        # Start wf-recorder and store its PID
        wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" &
        echo $! > "$PID_WF_RECORDER"

        notify-send "Recording started" "Run script again to stop"
        ;;
esac

