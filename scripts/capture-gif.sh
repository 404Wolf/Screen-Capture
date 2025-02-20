# Configuration with defaults
FPS="${FPS:-15}"
SAVE="${SAVE:-0}"

LOCK_FILE="/tmp/screen_recorder.lock"
PID_FILE="/tmp/screen_recorder.pid"
OUTPUT_FILE="/tmp/recording.gif"

# If saving is enabled, create a unique filename in ~/Screenshots
if [ "$SAVE" = "1" ]; then
    mkdir -p ~/Screenshots
    OUTPUT_FILE=~/Screenshots/recording_$(date +%Y%m%d_%H%M%S).gif
fi

cleanup() {
    rm -f "$LOCK_FILE" "$PID_FILE" "/tmp/recording.mkv"
}
trap cleanup EXIT

# If lock exists, stop recording
if [ -f "$LOCK_FILE" ]; then
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
    fi
    rm -f "$LOCK_FILE" "$PID_FILE"
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

notify-send "Screen Recording" "Recording started..."
wf-recorder --no-damage -g "$REGION" -f "/tmp/recording.mkv" &
echo $! > "$PID_FILE"

wait "$(cat "$PID_FILE")" || true

# Simple conversion to GIF
ffmpeg -i "/tmp/recording.mkv" \
    -vf "fps=$FPS,scale=640:-1:flags=lanczos" \
    "$OUTPUT_FILE"

# Clean up
rm -f "/tmp/recording.mkv"

# Copy to clipboard and notify
wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
notify-send "Screen Recording" "GIF saved to: $OUTPUT_FILE"
