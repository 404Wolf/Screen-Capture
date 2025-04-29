set -euxo pipefail

OUTPUT_FILE=/tmp/$(uuidgen)

# Exit if region selection is cancelled
REGION=$(slurp) || exit 1

# Check if SCREENSHOT_DELAY is set and apply delay after region selection
if [ -n "${SCREENSHOT_DELAY:-}" ]; then
    sleep "$SCREENSHOT_DELAY"
fi

# Take the screenshot
grim -g "$REGION" "$OUTPUT_FILE.png" || {
    exit 1
}

wl-copy --type "text/uri-list" "file://$OUTPUT_FILE"
