# Screen Capture

A unified screen capture utility for Wayland that supports capturing images, videos, and GIFs.

## Features

- **Image Capture**: Take screenshots of selected regions
- **Video Capture**: Record videos with optional audio
- **GIF Capture**: Create animated GIFs from screen recordings
- **Clipboard Integration**: Automatically copies captures to clipboard
- **Notification System**: Shows notifications when operations complete

## Installation

### Using Nix Flakes

```bash
# Install the package
nix profile install github:yourusername/Screen-Capture
```

## Usage

```bash
# Capture an image
screen-capture image

# Start recording a video (without audio)
screen-capture video
# Stop a video recording (ID is printed when recording starts)
screen-capture stop-video <recording-id>

# Start recording a video with audio
screen-capture video --audio

# Start/stop recording a GIF (toggle mode)
screen-capture gif
```

## Environment Variables

- `SCREENSHOT_DELAY`: Set a delay in seconds before capturing (applies to images)
- `AUDIO`: Set to "1" to include audio in video recordings

## Requirements

- Wayland compositor
- slurp (for region selection)
- grim (for image capture)
- wf-recorder (for video/GIF recording)
- wl-clipboard (for clipboard functionality)

## Output

All captures are saved to `~/Screenshots/` with unique filenames.
