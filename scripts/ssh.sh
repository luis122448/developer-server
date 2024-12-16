#!/bin/bash

source ./scripts/funtions.sh

# Generate the SSH keys
ssh-keygen -t rsa -b 4096 -C ""

# Add the SSH keys to the SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Send the SSH keys to the remote server
ssh-copy-id -i ~/.ssh/id_rsa.pub user@remote-server