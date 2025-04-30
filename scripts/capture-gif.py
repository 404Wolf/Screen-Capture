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
    try:
        # Stop recording
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())

        # First try sending SIGINT
        try:
            os.kill(pid, signal.SIGINT)
            # Wait a moment for clean shutdown
            subprocess.run(["sleep", "0.5"])
        except ProcessLookupError:
            # Process already gone, that's fine
            pass
            
        # Make sure the process is actually terminated
        try:
            os.kill(pid, 0)  # Check if process exists
            # If we get here, process still running, try SIGTERM
            os.kill(pid, signal.SIGTERM)
            # Wait a moment for termination
            subprocess.run(["sleep", "0.5"])
            
            # Last resort: SIGKILL
            try:
                os.kill(pid, 0)  # Check if process still exists
                os.kill(pid, signal.SIGKILL)  # Force kill
            except ProcessLookupError:
                pass  # Process terminated with SIGTERM, all good
        except ProcessLookupError:
            pass  # Process terminated with SIGINT, all good
            
        # Clean up PID file
        os.remove(PID_FILE)
        
        # Check if the recording exists and copy to clipboard
        if os.path.exists(OUTPUT_FILE):
            subprocess.run(["wl-copy", "--type", "text/uri-list", f"file://{OUTPUT_FILE}"])
        
        subprocess.run(["notify-send", "Recording stopped", "GIF copied to clipboard"])
        sys.exit(0)
    except Exception as e:
        subprocess.run(["notify-send", "Error stopping recording", str(e)])
        # Clean up PID file anyway
        os.remove(PID_FILE)
        sys.exit(1)

# Start new recording
try:
    # Get region with slurp
    region = subprocess.check_output(["slurp", "-d"]).decode().strip()

    # Start recording
    process = subprocess.Popen(["wf-recorder", "--no-damage", "-g", region, "-f", OUTPUT_FILE])
    
    # Save the process PID directly
    with open(PID_FILE, 'w') as f:
        f.write(str(process.pid))

    subprocess.run(["notify-send", "Recording started", "Run script again to stop"])

except Exception as e:
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    subprocess.run(["notify-send", "Error", str(e)])

