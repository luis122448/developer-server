#!/bin/bash

source /srv/developer-server/scripts/functions.sh

# Define the variables
DEVICE_NAME=${HOSTNAME}
IP_ADDRESS=$(get_config_value "$DEVICE_NAME" "IP")

# Parse the command-line options
while getopts "i" opt; do
    case $opt in
        i|--interface)
            INTERFACE=$OPTARG
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# Validate the configuration
echo "Step 1 - Validate Network Connection"
if ping -c 1 google.com &> /dev/null; then
    echo "  [OK] Network connection successful"
else
    echo "  [FAIL] Network connection failed"
fi

echo "Step 2 - Validate Static IP Address"
if ! ip link show $INTERFACE &> /dev/null; then
    echo "[FAIL] Network interface $INTERFACE not found"
    exit 1
fi

IP_STATIC_ADDRESS=$(ip -o -4 addr show $INTERFACE | awk '{print $4}' | cut -d'/' -f1)

echo "  Expected IP Address: $IP_ADDRESS"
echo "  Assigned IP Address: $IP_STATIC_ADDRESS"

if [ "$IP_STATIC_ADDRESS" == "$IP_ADDRESS" ]; then
    echo "  [OK] IP address configured successfully"
else
    echo "  [FAIL] IP address configuration failed"
fi