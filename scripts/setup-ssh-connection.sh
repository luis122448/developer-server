#!/bin/bash

source /etc/environment
source /srv/developer-server/scripts/functions.sh

# Define the variables
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
PUBLIC_KEY_PATH="$SSH_KEY_PATH.pub"

# Validate environment variables
if [ -z "$SERVER_LOCAL_USER" ]; then
    echo "The environment variables SERVER_LOCAL_USER and SERVER_LOCAL_IP must be set."
    exit 1
fi

IPS=$(get_all_values "IP")

# Copy the SSH key to the remote servers
for IP in $IPS; do
    echo "IP: $IP"
    ssh-copy-id -i "$PUBLIC_KEY_PATH" -o StrictHostKeyChecking=no "$SERVER_LOCAL_USER@$IP"
done