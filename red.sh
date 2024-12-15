#!/bin/bash

# Define the variables
VERSION=1.0.0
DEVICE_NAME=${HOSTNAME}
CONFIG_FILE=./config.ini
CONFIG_FILE_NETPLAN="/etc/netplan/01-netcfg.yaml"
IP_ADDRESS=''
IP_GATEWAY='192.168.100.1'
MAC_ADDRESS=''
INTERFACE='enp1s0'

# Define the functions
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Display this help message."
    echo "  -i, --interface Specify the network interface."
    echo "  -g, --gateway   Specify the gateway IP address."
    exit 0
}

get_config_value() {
    local section=$1
    local key=$2
    awk -F'=' -v section="[$section]" -v key="$key" '
    $0 ~ section {found_section=1}
    found_section && $1 == key {print $2; exit}
    ' "$CONFIG_FILE"
}

write_config_value() {
    local section=$1
    local key=$2
    local value=$3
    local temp_file=$(mktemp)

    awk -F'=' -v section="[$section]" -v key="$key" -v value="$value" '
    $0 ~ section {found_section=1}
    found_section && $1 == key {sub($2, value); found_key=1}
    found_section && /^\[/ {found_section=0}
    {print}
    END {
        if (!found_key) {
            print key "=" value
        }
    }
    ' "$CONFIG_FILE" > "$temp_file"
}

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

if [ -z "$IP_ADDRESS" ]; then
    echo "IP address not found in the config file"
    exit 1
fi

# Get MAC address
MAC_ADDRESS=$(ip link show $INTERFACE | awk '/ether/ {print $2}')

if [ -z "$MAC_ADDRESS" ]; then
    echo "MAC address not found, recheck the network interface"
    exit 1
fi

# # Write the configuration
write_config_value "$DEVICE_NAME" "MAC" "$MAC_ADDRESS"

# # Create the Netplan configuration file
# cat << EOF > /tmp/netcfg.yaml
# network:
#   renderer: networkd
#   ethernets:
#     ens33:
#       addresses:
#         - $IP_ADDRESS/24
#       routes:
#         - to: default
#           via: $IP_GATEWAY
#       nameservers:
#         addresses:
#           - 8.8.8.8
#           - 8.8.4.4
#   version: 2
# EOF

# mv /tmp/netcfg.yaml $CONFIG_FILE_NETPLAN
# chmod 600 $CONFIG_FILE_NETPLAN
# chown root:root $CONFIG_FILE_NETPLAN

# # Apply the configuration
# netplan apply

# # Validate the connection
# if ping -c 1 google.com &> /dev/null; then
#     echo "Connection successful"
# else
#     echo "Connection failed"
# fi