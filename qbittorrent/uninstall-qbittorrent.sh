#!/bin/bash
set -e 

# --- Check Root ---
if [ "$EUID" -ne 0 ]; then echo "Please run with sudo."; exit 1; fi

# --- Check if Installed ---
echo "--- Checking for qBittorrent-nox installation ---"
if ! dpkg -s qbittorrent-nox &>/dev/null; then
    echo "qBittorrent-nox is not installed. No uninstallation needed."
    exit 0
else
    echo "qBittorrent-nox found. Proceeding with uninstallation."
fi

# --- Uninstallation Steps ---
echo "--- Stopping service ---"
systemctl stop qbittorrent-nox || true

echo "--- Purging package ---"
apt purge -y qbittorrent-nox

echo "--- Removing user data and config directories ---"
if [ -d "/var/lib/qbittorrent-nox" ]; then
    echo "Removing /var/lib/qbittorrent-nox..."
    rm -rf /var/lib/qbittorrent-nox
fi

echo "--- Removing user and group ---"
deluser --force --remove-home qbittorrent-nox || true
delgroup qbittorrent-nox || true

echo "--- Removing systemd service file ---"
rm -f "/etc/systemd/system/qbittorrent-nox.service"

echo "--- Reloading systemd daemon ---"
systemctl daemon-reload

# --- Final Message ---
echo "--- Uninstallation Complete ---"
echo "qbittorrent-nox package, user, group, service file, and config data removed."
echo ""
echo "NOTE: Your download directory ($DOWNLOAD_DIR - or wherever you configured it)"
echo "has NOT been removed as it may contain your files."