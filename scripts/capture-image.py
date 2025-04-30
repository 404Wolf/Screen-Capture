#!/usr/bin/env python3
import os
import subprocess
import sys
import uuid

# Generate unique output file name
output_file = f"/tmp/{uuid.uuid4()}"

try:
    # Get region selection using slurp
    region = subprocess.check_output(["slurp"]).decode().strip()
    
    # Check if SCREENSHOT_DELAY is set and apply delay
    delay = os.environ.get("SCREENSHOT_DELAY")
    if delay:
        subprocess.run(["sleep", delay])
    
    # Take the screenshot
    subprocess.run(["grim", "-g", region, f"{output_file}.png"], check=True)
    
    # Copy to clipboard
    subprocess.run(["wl-copy", "--type", "text/uri-list", f"file://{output_file}.png"], check=True)
    
except subprocess.CalledProcessError:
    # Exit if region selection is cancelled or screenshot fails
    sys.exit(1)