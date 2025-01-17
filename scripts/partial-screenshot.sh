set -x

FILEPATH=/tmp/$(uuidgen)
grim -g "$(slurp)" "$FILEPATH.png"
wl-copy --type "text/uri-list" "file://$FILEPATH.png"
notify-send "Successfully saved screen capture!" "The png has been saved to $FILEPATH"
