#!/bin/bash
# This script performs first-run desktop initialization.
# It ensures the Desktop directory exists and copies default files.

# 1. Ensure the Desktop directory exists.
mkdir -p /config/Desktop

# 2. Copy wallpaper and icons to the Desktop.
# The -n flag (no-clobber) prevents overwriting if the files already exist from a previous run.
cp -n /tmp/background.png /config/Desktop/
cp -n /tmp/desktop_icons/*.desktop /config/Desktop/