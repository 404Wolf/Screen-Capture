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
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        pkill -P "$(cat "$PID_FILE")" 2>/dev/null || true
    fi
    rm -f "$LOCK_FILE" "$PID_FILE"
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

TEMP_FILE="/tmp/temp_recording.mkv"
wf-recorder --no-damage -g "$REGION" -f "$TEMP_FILE" &
RECORDER_PID=$!
echo $RECORDER_PID > "$PID_FILE"

wait $RECORDER_PID || true

# Convert to optimized GIF
ffmpeg -i "$TEMP_FILE" -vf "fps=$FPS,scale=min(iw\,$MAX_WIDTH):-1" \
    -q:v "$QUALITY" -y "$OUTPUT_FILE" 2>/dev/null

# Clean up temporary files
rm -f "$TEMP_FILE"

# Copy to clipboard
wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
