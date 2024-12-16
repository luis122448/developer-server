#!/bin/bash

source /srv/developer-server/scripts/functions.sh
source /etc/environment

# Define the variables
IP_ADDRESS=$(get_config_value "$DEVICE_NAME" "IP")
REMOTE_SERVER=$SERVER_LOCAL_USER@$SERVER_LOCAL_IP
CONFIG_FILE="$HOME/.ssh/config"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
PUBLIC_KEY_PATH="$SSH_KEY_PATH.pub"
GITHUB_KEYS_DIR="$HOME/.ssh/github_keys"

# Validate environment variables
if [ -z "$SERVER_LOCAL_USER" ] || [ -z "$SERVER_LOCAL_IP" ]; then
    echo "The environment variables SERVER_LOCAL_USER and SERVER_LOCAL_IP must be set."
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "The environment variable EMAIL must be set."
    exit 1
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH" -N ""
else
    echo "SSH key already exists."
fi

eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
fi

if ! grep -q "$REMOTE_SERVER" "$CONFIG_FILE"; then
    echo -e "\nHost $REMOTE_SERVER\n\tHostName $(echo $REMOTE_SERVER | cut -d@ -f2)\n\tUser $(echo $REMOTE_SERVER | cut -d@ -f1)\n\tIdentityFile $SSH_KEY_PATH" >> "$CONFIG_FILE"
else
    echo "The configuration for $REMOTE_SERVER already exists in $CONFIG_FILE."
fi

echo "Copying the SSH key to the remote server $REMOTE_SERVER"
ssh-copy-id -i "$PUBLIC_KEY_PATH" "$REMOTE_SERVER"
ssh "$SERVER_LOCAL_USER@$SERVER_LOCAL_IP" "mkdir -p $GITHUB_KEYS_DIR"
scp "$PUBLIC_KEY_PATH" "$SERVER_LOCAL_USER@$SERVER_LOCAL_IP:$GITHUB_KEYS_DIR/key_$IP_ADDRESS.pub"