#!/bin/bash
set -e 

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
WebUI\\AuthSubnetWhitelistEnabled=false
WebUI\\LocalHostAuth=false
WebUI\\CSRFProtection=true
WebUI\\HTTPS\\Enabled=false
# WebUI\\HTTPS\\KeyPath=
# WebUI\\HTTPS\\CertPath=
# WebUI\\HTTPS\\KeyPassphrase=
# WebUI\\HTTPS\\Port=443
WebUI\\Title=qBittorrent
WebUI\\Language=en
WebUI\\Theme=dark
WebUI\\DownloadLimit=0
WebUI\\UploadLimit=0
WebUI\\DownloadLimitEnabled=false
WebUI\\UploadLimitEnabled=false
WebUI\\Search\\Engines=1337x|1337x|Torrentz2|Torrentz2|Nyaa|Nyaa|RARBG|RARBG|YTS|YTS|EZTV|EZTV
WebUI\\Search\\EnginesOrder=1337x|Torrentz2|Nyaa|RARBG|YTS|EZTV
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

# --- Final Status ---
echo "--- Service status ---"
systemctl status qbittorrent-nox.service --no-pager || true

echo "--- Setup Complete ---"
echo "qBittorrent-nox configured. Web UI: http://<your_server_ip>:$WEBUI_PORT"
echo "Default download dir: $DOWNLOAD_DIR"