#!/usr/bin/env python3
import os
import subprocess
import signal
import sys
import time
from datetime import datetime

# Configuration with defaults
SAVE = os.environ.get("SAVE", "0")
AUDIO = os.environ.get("AUDIO", "0")
FORMAT = os.environ.get("FORMAT", "mp4")

LOCK_FILE = "/tmp/screen_recorder_video.lock"
PID_FILE = "/tmp/screen_recorder_video.pid"
OUTPUT_FILE = f"/tmp/recording.{FORMAT}"

# If saving is enabled, create a unique filename in ~/Videos
if SAVE == "1":
    videos_dir = os.path.expanduser("~/Videos")
    os.makedirs(videos_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    OUTPUT_FILE = f"{videos_dir}/recording_{timestamp}.{FORMAT}"

def cleanup():
    """Remove lock and pid files, kill any child processes"""
    if os.path.exists(LOCK_FILE):
        os.remove(LOCK_FILE)
    
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as f:
                pid = int(f.read().strip())
            # Try to kill child processes
            subprocess.run(["pkill", "-P", str(pid)], stderr=subprocess.DEVNULL)
        except:
            pass
        
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)

# If lock exists, stop recording
if os.path.exists(LOCK_FILE):
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as f:
                pid = int(f.read().strip())
            # Kill the recording process
            os.kill(pid, signal.SIGTERM)
            # Kill any child processes
            subprocess.run(["pkill", "-P", str(pid)], stderr=subprocess.DEVNULL)
            time.sleep(0.5)
        except:
            pass
    
    cleanup()
    
    # Check if the recording exists
    if os.path.exists(OUTPUT_FILE):
        # Copy to clipboard
        subprocess.run(["wl-copy", "--type", "text/uri-list", f"file://{OUTPUT_FILE}"])
    
    sys.exit(0)

# Start new recording
try:
    # Create lock file
    with open(LOCK_FILE, 'w') as f:
        f.write('')
    
    # Get region with slurp
    region = subprocess.check_output(["slurp", "-d"]).decode().strip()
    
    # Recording command with or without audio
    cmd = ["wf-recorder", "--no-damage", "-g", region, "-f", OUTPUT_FILE]
    if AUDIO == "1":
        cmd.append("-a")
    
    # Start recording process
    process = subprocess.Popen(cmd)
    
    # Save PID
    with open(PID_FILE, 'w') as f:
        f.write(str(process.pid))
    
    # Wait for process to complete (when user runs script again)
    process.wait()
    
except subprocess.CalledProcessError:
    # Exit if region selection is cancelled
    cleanup()
    sys.exit(1)
except KeyboardInterrupt:
    # Handle Ctrl+C
    cleanup()
    sys.exit(0)
except Exception as e:
    cleanup()
    sys.exit(1)