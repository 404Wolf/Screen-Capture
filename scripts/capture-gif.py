#!/usr/bin/env python3
import os
import subprocess
import signal
import sys
from datetime import datetime

PID_FILE = "/tmp/screen_recorder.pid"
OUTPUT_FILE = "/tmp/recording.gif"

# Check if recording is already running
if os.path.exists(PID_FILE):
    # Stop recording
    with open(PID_FILE, 'r') as f:
        pid = int(f.read().strip())

    # Send Ctrl+C signal
    os.kill(pid, signal.SIGINT)
    os.remove(PID_FILE)
    
    # Check if the recording exists and copy to clipboard
    if os.path.exists(OUTPUT_FILE):
        subprocess.run(["wl-copy", "--type", "text/uri-list", f"file://{OUTPUT_FILE}"])
    
    subprocess.run(["notify-send", "Recording stopped", "GIF copied to clipboard"])
    sys.exit(0)

# Start new recording
try:
    # Get region with slurp
    region = subprocess.check_output(["slurp", "-d"]).decode().strip()

    # Start recording
    process = subprocess.Popen(["wf-recorder", "--no-damage", "-g", region, "-f", OUTPUT_FILE])

    # Save PID
    with open(PID_FILE, 'w') as f:
        f.write(str(process.pid))

    subprocess.run(["notify-send", "Recording started", "Run script again to stop"])

except Exception as e:
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    subprocess.run(["notify-send", "Error", str(e)])

