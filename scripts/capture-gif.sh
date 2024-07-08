FILEPATH="/tmp/$(uuidgen)"
mkdir -p "$FILEPATH/frames/"
REGION=$(${slurp} -d)
$wf_recorder -g "$REGION" -f "$FILEPATH/recording.mkv"
$ffmpeg -i "$FILEPATH/recording.mkv" -vf "fps=$FPS,scale=640:-1:flags=lanczos" "$FILEPATH/frames/frame%04d.png"
$gifski -o "$FILEPATH/output.gif" "$FILEPATH"/frames/frame*.png --fps "$FPS" --quality "$QUALITY"
$wl_copy --type "text/uri-list" "file://$FILEPATH/output.gif"
$notify "Successfully saved gif!" "The gif has been saved to ${OUTPATH:FILEPATH}"