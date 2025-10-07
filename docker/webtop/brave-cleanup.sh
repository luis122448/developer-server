#!/bin/bash
# Clean up Brave browser lock files on startup to prevent profile lock errors.
rm -f /config/.config/BraveSoftware/Brave-Browser/Singleton*
