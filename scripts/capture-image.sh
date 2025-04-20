set -euxo pipefail

FILEPATH=/tmp/$(uuidgen)

# Exit if region selection is cancelled
REGION=$(slurp) || exit 1

# Check if SCREENSHOT_DELAY is set and apply delay after region selection
if [ -n "${SCREENSHOT_DELAY:-}" ]; then
    sleep "$SCREENSHOT_DELAY"
fi

# Take the screenshot
grim -g "$REGION" "$FILEPATH.png" || {
    notify-send "Screenshot Failed" "Could not capture screenshot"
    exit 1
}

# Copy to clipboard
if ! wl-copy --type "text/uri-list" "file://$FILEPATH.png"; then
    notify-send "Warning" "Screenshot saved but clipboard copy failed"
fi

notify-send "Screenshot Captured" "Saved to: $FILEPATH.png"

