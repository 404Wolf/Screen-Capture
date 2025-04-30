FPS="${FPS:-15}"
QUALITY="${QUALITY:-90}"
MAX_WIDTH="${MAX_WIDTH:-800}"

LOCK_FILE="/tmp/screen_recorder.lock"
PID_FILE="/tmp/screen_recorder.pid"

mkdir -p ~/Screenshots
OUTPUT_FILE=~/Screenshots/recording_$(date +%Y%m%d_%H%M%S).gif

cleanup() {
    rm -f "$LOCK_FILE" "$PID_FILE"
}
trap cleanup EXIT INT TERM

# If lock exists, stop recording
if [ -f "$LOCK_FILE" ]; then
    if [ -f "$PID_FILE" ] && [ -s "$PID_FILE" ]; then
        RECORDER_PID=$(cat "$PID_FILE")
        if kill -TERM "$RECORDER_PID" 2>/dev/null; then
            # Give the recorder time to gracefully shut down
            sleep 1
            # Only forcefully kill if still running
            kill -0 "$RECORDER_PID" 2>/dev/null && kill -KILL "$RECORDER_PID" 2>/dev/null
        fi
        # Wait a moment for processes to clean up
        sleep 0.5
    fi
    rm -f "$LOCK_FILE" "$PID_FILE"
    notify-send "Recording stopped" "Converting to GIF..."
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

TEMP_FILE="/tmp/temp_recording.mkv"
wf-recorder --no-damage -g "$REGION" -f "$TEMP_FILE" &
RECORDER_PID=$!
echo $RECORDER_PID > "$PID_FILE"

notify-send "Recording started" "Run script again to stop"

wait $RECORDER_PID || true

# Convert to optimized GIF
ffmpeg -i "$TEMP_FILE" -vf "fps=$FPS,scale=min(iw\,$MAX_WIDTH):-1" \
    -q:v "$QUALITY" -y "$OUTPUT_FILE" 2>/dev/null

# Clean up temporary files
rm -f "$TEMP_FILE"

# Copy to clipboard
wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
notify-send "Recording saved" "$OUTPUT_FILE"
