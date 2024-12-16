#!/bin/bash

# Define the variables
VERSION=1.0.0
DEVICE_NAME=${HOSTNAME}
CONFIG_FILE_NETPLAN="/etc/netplan/01-netcfg.yaml"
IP_ADDRESS=''
IP_GATEWAY='192.168.100.1'
MAC_ADDRESS=''

source /srv/developer-server/scripts/functions.sh
source /etc/environment

# Parse the command-line options
while getopts "hi:g:" opt; do
    case $opt in
        h|--help)
            show_usage
            exit 0
            ;;
        i|--interface)
            INTERFACE=$OPTARG
            ;;
        g|--gateway)
            IP_GATEWAY=$OPTARG
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# Validations
if [[ $EUID -ne 0 ]]; then
    echo "[FAIL] This script must be run as root."
    exit 1
fi

if [ -z "$INTERFACE" ]; then
    echo "Error: The -i or --interface option is mandatory."
    show_usage
    exit 1
fi

# Get IP Static address
IP_ADDRESS=$(get_config_value "$DEVICE_NAME" "IP")

# Get MAC address
MAC_ADDRESS=$(ip link show $INTERFACE | awk '/ether/ {print $2}')

if [ -z "$MAC_ADDRESS" ]; then
    echo "[FAIL] MAC address not found"
    exit 1
fi

# Write the configuration
write_config_value "$DEVICE_NAME" "MAC" "$MAC_ADDRESS"

echo "Configuring network interface $INTERFACE with IP address $IP_ADDRESS and MAC address $MAC_ADDRESS"

# Create the Netplan configuration file
umask 077
cat << EOF > /tmp/netcfg.yaml
network:
  renderer: networkd
  ethernets:
    ens33:
      addresses:
        - $IP_ADDRESS/24
      routes:
        - to: default
          via: $IP_GATEWAY
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
  version: 2
EOF

mv /tmp/netcfg.yaml $CONFIG_FILE_NETPLAN
chmod 600 $CONFIG_FILE_NETPLAN
chown root:root $CONFIG_FILE_NETPLAN

# Apply the configuration
netplan apply