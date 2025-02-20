# Configuration with defaults
FPS="${FPS:-15}"
QUALITY="${QUALITY:-80}"
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
    rm -f "$LOCK_FILE" "$PID_FILE"
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
wf-recorder --no-damage -g "$REGION" -f "$OUTPUT_FILE.mkv" &
echo $! > "$PID_FILE"

wait "$(cat "$PID_FILE")"

# Convert to high quality GIF using a better palette
palette="/tmp/palette.png"
filters="fps=$FPS,scale=-1:-1:flags=lanczos"

# Generate a high quality palette
ffmpeg -i "$OUTPUT_FILE.mkv" -vf "$filters,palettegen=max_colors=256:stats_mode=full" -y "$palette"

# Convert to GIF with the custom palette
ffmpeg -i "$OUTPUT_FILE.mkv" -i "$palette" \
    -lavfi "$filters [x]; [x][1:v] paletteuse=dither=floyd_steinberg:bayer_scale=5:diff_mode=rectangle" \
    -y "$OUTPUT_FILE"

# Clean up temporary files
rm -f "$OUTPUT_FILE.mkv" "$palette"

# Copy to clipboard
wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
notify-send "Screen Recording" "GIF saved to: $OUTPUT_FILE"
