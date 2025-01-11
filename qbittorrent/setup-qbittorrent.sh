#!bin/bash

# Define the variables
SERVICE_FILE_QBITTORRENT=/etc/systemd/system/qbittorrent-nox.service
CONFIG_FILE_QBITTORRENT=/var/lib/qbittorrent-nox/.config/qBittorrent/qBittorrent.conf
PASSWORD_QBITTORRENT=''

source /etc/environment

# Parse the command-line options
while getopts "hp:" opt; do
    case $opt in
        h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h, --help      Display this help message."
            echo "  -p, --password  Specify the password for the qBittorrent web interface."
            exit 0
            ;;
        p|--password)
            PASSWORD_QBITTORRENT=$OPTARG
            ;;
        *)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h, --help      Display this help message."
            echo "  -p, --password  Specify the password for the qBittorrent web interface."
            exit 1
            ;;
    esac
done

if [ -z "$PASSWORD_QBITTORRENT" ]; then
    echo "Error: The -p or --password option is mandatory."
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Display this help message."
    echo "  -p, --password  Specify the password for the qBittorrent web interface."
    exit 1
fi

# Credits:https://linuxcapable.com/how-to-install-qbittorrent-on-ubuntu-linux/
sudo apt install qbittorrent-nox

sudo adduser --system --group qbittorrent-nox
sudo usermod -d /var/lib/qbittorrent-nox qbittorrent-nox

sudo mkdir -p /var/lib/qbittorrent-nox/.cache/qBittorrent
sudo mkdir -p /var/lib/qbittorrent-nox/.config/qBittorrent

sudo chown -R qbittorrent-nox:qbittorrent-nox /var/lib/qbittorrent-nox
sudo chmod -R 755 /var/lib/qbittorrent-nox

sudo adduser $USER qbittorrent-nox

sudo systemctl stop qbittorrent-nox

# Create the service file
cat << EOF > /tmp/qbittorrent-nox.service
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
Type=forking
User=qbittorrent-nox
Group=qbittorrent-nox
UMask=007
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/qbittorrent-nox.service $SERVICE_FILE_QBITTORRENT

PASSWORD_HASH=$(echo -n $PASSWORD_QBITTORRENT | sha1sum | awk '{print $1}')

cat << EOF > /tmp/qbittorrent-nox.conf
[BitTorrent]
Session\Port=35118
Session\QueueingSystemEnabled=false

[Meta]
MigrationVersion=6

[Network]
Cookies=@Invalid()

[Preferences]
WebUI\AuthSubnetWhitelist=192.168.100.161/24, 192.168.100.162/24
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\UseUPnP=false
EOF

sudo mv /tmp/qbittorrent-nox.conf $CONFIG_FILE_QBITTORRENT

# Reload the systemd manager configuration
sudo systemctl daemon-reload

sudo systemctl start qbittorrent-nox
sudo systemctl enable qbittorrent-nox

sudo systemctl status qbittorrent-nox.service
