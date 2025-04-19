# Configuration with defaults
FPS="${FPS:-15}"
QUALITY="${QUALITY:-90}"
MAX_WIDTH="${MAX_WIDTH:-800}"
MAX_SIZE="${MAX_SIZE:-8}" # Max size in MB for Discord (8MB limit)

LOCK_FILE="/tmp/screen_recorder.lock"
PID_FILE="/tmp/screen_recorder.pid"
OUTPUT_FILE="/tmp/recording.gif"

mkdir -p ~/Screenshots
OUTPUT_FILE=~/Screenshots/recording_$(date +%Y%m%d_%H%M%S).gif

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
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

notify-send "Screen Recording" "Recording started..."
wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE.mkv" &
RECORDER_PID=$!
echo $RECORDER_PID > "$PID_FILE"

wait $RECORDER_PID || true

notify-send "Screen Recording" "Processing GIF..."

# Convert to optimized GIF
palette="/tmp/palette.png"
# Scale down if necessary (for faster loading) and use lower FPS
filters="fps=$FPS,scale=min(iw\,$MAX_WIDTH):min(ih\,trunc(oh*a/2)*2)"

# Generate an optimized palette
ffmpeg -i "$OUTPUT_FILE.mkv" -vf "$filters,palettegen=max_colors=128:stats_mode=diff" -y "$palette" 2>/dev/null

# Convert to GIF with optimized settings for Discord
ffmpeg -i "$OUTPUT_FILE.mkv" -i "$palette" \
    -lavfi "$filters [x]; [x][1:v] paletteuse=dither=sierra2_4a:diff_mode=rectangle" \
    -y "$OUTPUT_FILE" 2>/dev/null

# Clean up temporary files
rm -f "$OUTPUT_FILE.mkv" "$palette"

# Copy to clipboard
wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
notify-send "Screen Recording" "GIF saved to: $OUTPUT_FILE"
