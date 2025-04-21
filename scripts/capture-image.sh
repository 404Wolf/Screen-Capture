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
    exit 1
}

