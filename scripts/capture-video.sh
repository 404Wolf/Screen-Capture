# Configuration with defaults
SAVE="${SAVE:-0}"
AUDIO="${AUDIO:-0}"
FORMAT="${FORMAT:-mp4}"

LOCK_FILE="/tmp/screen_recorder_video.lock"
PID_FILE="/tmp/screen_recorder_video.pid"
OUTPUT_FILE="/tmp/recording.$FORMAT"

# If saving is enabled, create a unique filename in ~/Videos
if [ "$SAVE" = "1" ]; then
    mkdir -p ~/Videos
    OUTPUT_FILE=~/Videos/recording_$(date +%Y%m%d_%H%M%S).$FORMAT
fi

cleanup() {
    rm -f "$LOCK_FILE" "$PID_FILE"
    # Safety cleanup for any leftover processes
    if [ -f "$PID_FILE" ]; then
        pkill -P "$(cat "$PID_FILE")" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# If lock exists, stop recording
if [ -f "$LOCK_FILE" ]; then
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        # Kill any child processes
        pkill -P "$(cat "$PID_FILE")" 2>/dev/null || true
        sleep 0.5
    fi
    rm -f "$LOCK_FILE" "$PID_FILE"
    
    # Check if the recording exists
    if [ -f "$OUTPUT_FILE" ]; then
        # Copy to clipboard
        wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
    fi
    
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

# Recording command with or without audio
if [ "$AUDIO" = "1" ]; then
    wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" -a &
else
    wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE" &
fi

RECORDER_PID=$!
echo $RECORDER_PID > "$PID_FILE"

# Wait for user to run the script again to stop recording
wait $RECORDER_PID || true
