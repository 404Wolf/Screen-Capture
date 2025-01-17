OUTPATH=$(zenity --file-selection --directory --save --title "Choose where to save the GIF");
TO_DUMP=$(wl-paste | sed 's#^file://##')
OUT_FILENAME=$(basename "$TO_DUMP")
OUTPATH="$OUTPATH/$OUT_FILENAME"
cat "$TO_DUMP" > "$OUTPATH"
notify-send "Clipboard dumped to $OUTPATH";
