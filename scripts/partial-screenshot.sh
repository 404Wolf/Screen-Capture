FILEPATH=/tmp/$(uuidgen)
$grim -g "$($slurp)" "$FILEPATH.png"
$wl_copy --type "text/uri-list" "file://$FILEPATH.png"
$notify "Successfully saved screen capture!" "The png has been saved to $FILEPATH"
