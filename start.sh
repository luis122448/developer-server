#!/bin/bash

source ./scripts/funtions.sh

# Define the variables
VERSION=1.0.0
DEVICE_NAME=${HOSTNAME}
CONFIG_FILE=./config/config.ini
CONFIG_FILE_NETPLAN="/etc/netplan/01-netcfg.yaml"
IP_ADDRESS=''
IP_GATEWAY='192.168.100.1'
MAC_ADDRESS=''
INTERFACE='enp1s0'

# Parse the command-line options
while getopts "hig" opt; do
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
    echo "This script must be run as root."
    exit 1
fi

if [ ! -f ${CONFIG_FILE} ]; then
    echo "Config file not found"
    exit 1
fi

# Get IP Static address
IP_ADDRESS=$(get_config_value "$DEVICE_NAME" "IP")

# Get MAC address
MAC_ADDRESS=$(ip link show $INTERFACE | awk '/ether/ {print $2}')

if [ -z "$MAC_ADDRESS" ]; then
    echo "MAC address not found, recheck the network interface"
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

# Validate the connection
if ping -c 1 google.com &> /dev/null; then
    echo "Connection successful"
else
    echo "Connection failed"
fi

# Validate the configuration
ip addr show $INTERFACE