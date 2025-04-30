FPS="${FPS:-15}"
QUALITY="${QUALITY:-90}"
MAX_WIDTH="${MAX_WIDTH:-800}"

LOCK_FILE="/tmp/screen_recorder.lock"
PID_FILE="/tmp/screen_recorder.pid"
TEMP_FILE="/tmp/temp_recording.mkv"

mkdir -p ~/Screenshots
OUTPUT_FILE=~/Screenshots/recording_$(date +%Y%m%d_%H%M%S).gif

# If lock exists, stop recording
if [ -f "$LOCK_FILE" ]; then
    RECORDER_PID=$(cat "$PID_FILE" 2>/dev/null)

    # Kill recording process if it exists
    if [ -n "$RECORDER_PID" ]; then
        kill -TERM "$RECORDER_PID" 2>/dev/null
        sleep 1
    fi

    # Convert to GIF
    notify-send "Recording stopped" "Converting to GIF..."
    ffmpeg -i "$TEMP_FILE" -vf "fps=$FPS,scale=min(iw\,$MAX_WIDTH):-1" \
        -q:v "$QUALITY" -y "$OUTPUT_FILE" 2>/dev/null

    # Clean up
    rm -f "$TEMP_FILE" "$LOCK_FILE" "$PID_FILE"

    # Copy to clipboard
    wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
    notify-send "Recording saved" "$OUTPUT_FILE"
    exit 0
fi

# Start new recording
touch "$LOCK_FILE"
REGION=$(slurp -d) || { rm -f "$LOCK_FILE"; exit 1; }

wf-recorder --no-damage -g "$REGION" -f "$TEMP_FILE" &
echo $! > "$PID_FILE"

notify-send "Recording started" "Run script again to stop"
exit 0
