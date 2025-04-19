#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Variable Definitions ---
SERVICE_FILE="/etc/systemd/system/qbittorrent-nox.service"
CONFIG_FILE="/var/lib/qbittorrent-nox/.config/qBittorrent/qBittorrent.conf"
DEFAULT_WEBUI_PORT="8080"
WEBUI_PORT="$DEFAULT_WEBUI_PORT"
DOWNLOAD_DIR="/mnt/torrent/downloads" # Your preferred download path

# --- Option Parsing ---
while getopts "hw:" opt; do
    case $opt in
        h|\? )
            echo "Usage: $0 [options]"
            echo "Install and configure qBittorrent-nox as a systemd service."
            echo "Options:"
            echo "  -h, --help      Show this help message."
            echo "  -w PORT         Specify Web UI port (default: $DEFAULT_WEBUI_PORT)."
            exit 0
            ;;
        w ) WEBUI_PORT=$OPTARG
            if ! [[ "$WEBUI_PORT" =~ ^[0-9]+$ ]]; then echo "Error: Port must be a number." >&2; exit 1; fi
            if (( WEBUI_PORT < 1024 || WEBUI_PORT > 65535 )); then echo "Warning: Port $WEBUI_PORT outside typical range." >&2; fi
            ;;
    esac
done
shift $((OPTIND-1))

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then echo "Please run with sudo."; exit 1; fi

# --- Clean Uninstall (if exists) ---
echo "--- Checking for existing installation ---"
if dpkg -s qbittorrent-nox &>/dev/null; then
    echo "Existing installation found. Performing clean uninstallation..."
    systemctl stop qbittorrent-nox || true
    apt purge -y qbittorrent-nox
    if [ -d "/var/lib/qbittorrent-nox" ]; then rm -rf /var/lib/qbittorrent-nox; fi # Remove service user home
    deluser --force --remove-home qbittorrent-nox || true
    delgroup qbittorrent-nox || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    echo "Uninstallation complete."
else
    echo "No existing installation found."
fi

# --- Install qBittorrent-nox ---
echo "--- Installing qBittorrent-nox ---"
apt update && apt install -y qbittorrent-nox

# --- Setup User and Directories ---
echo "--- Setting up user and directories ---"
if ! id "qbittorrent-nox" &>/dev/null; then adduser --system --group qbittorrent-nox; fi
usermod -d /var/lib/qbittorrent-nox qbittorrent-nox
mkdir -p /var/lib/qbittorrent-nox/.cache/qBittorrent
mkdir -p /var/lib/qbittorrent-nox/.config/qBittorrent
mkdir -p "$DOWNLOAD_DIR"
chown -R qbittorrent-nox:qbittorrent-nox /var/lib/qbittorrent-nox "$DOWNLOAD_DIR"
chmod -R 755 /var/lib/qbittorrent-nox
adduser $SUDO_USER qbittorrent-nox || true # Add calling user to group

# --- Create Systemd Service File ---
echo "--- Creating systemd service file ---"
cat << EOF > /tmp/qbittorrent-nox.service
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
Type=forking
User=qbittorrent-nox
Group=qbittorrent-nox
UMask=007
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=$WEBUI_PORT
Restart=on-failure
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
mv /tmp/qbittorrent-nox.service "$SERVICE_FILE"

# --- Create Configuration File ---
echo "--- Creating configuration file ---"
cat << EOF > /tmp/qbittorrent-nox.conf
[BitTorrent]
Session\\Port=35118
Session\\QueueingSystemEnabled=false

[Meta]
MigrationVersion=6

[Network]
Cookies=@Invalid()

[Preferences]
WebUI\\Port=$WEBUI_PORT
WebUI\\UseUPnP=false
Downloads\\SavePath=$DOWNLOAD_DIR
EOF
mv /tmp/qbittorrent-nox.conf "$CONFIG_FILE"
chown qbittorrent-nox:qbittorrent-nox "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"

# --- Start and Enable Service ---
echo "--- Starting and enabling service ---"
systemctl daemon-reload
systemctl enable qbittorrent-nox
systemctl start qbittorrent-nox

# --- Retrieve Initial Password ---
echo "--- Retrieving initial Web UI password from logs ---"
sleep 20 # Wait for service to start and log password
initial_password=$(sudo journalctl -u qbittorrent-nox.service --since "2 minutes ago" | grep "The WebUI password is" | tail -n 1 | sed -n "s/.*The WebUI password is '\(.*\)'/\1/p")

if [ -n "$initial_password" ]; then
    echo ""
    echo "--- Initial Web UI Credentials ---"
    echo "User: admin"
    echo "Password: $initial_password"
    echo "----------------------------------"
    echo "ACTION: Log in with these and CHANGE the password via Web UI."
    echo ""
else
    echo ""
    echo "WARNING: Could not auto-retrieve initial password from logs."
    echo "ACTION: Find it manually: 'sudo journalctl -u qbittorrent-nox.service'"
    echo "Look for 'The WebUI password is' line near service start time."
    echo ""
fi

# --- Final Status ---
echo "--- Service status ---"
systemctl status qbittorrent-nox.service --no-pager || true

echo "--- Setup Complete ---"
echo "qBittorrent-nox configured. Web UI: http://<your_server_ip>:$WEBUI_PORT"
echo "Default download dir: $DOWNLOAD_DIR"