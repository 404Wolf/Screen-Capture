import os
import subprocess
import signal
import sys

PID_FILE = "/tmp/screen_recorder.pid"

# Check if recording is already running
if os.path.exists(PID_FILE):
    # Stop recording
    with open(PID_FILE, 'r') as f:
        pid = int(f.read().strip())

    # Send Ctrl+C signal
    os.kill(pid, signal.SIGINT)
    os.remove(PID_FILE)
    subprocess.run(["notify-send", "Recording stopped", ""])
    sys.exit(0)

# Start new recording
try:
    # Get region with slurp
    region = subprocess.check_output(["slurp", "-d"]).decode().strip()

    # Start recording
    process = subprocess.Popen(["wf-recorder", "--no-damage", "-g", region])

    # Save PID
    with open(PID_FILE, 'w') as f:
        f.write(str(process.pid))

    subprocess.run(["notify-send", "Recording started", "Run script again to stop"])

except Exception as e:
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    subprocess.run(["notify-send", "Error", str(e)])

