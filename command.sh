#!/bin/bash

# Define the variables
VERSION=1.0.0
DEVICE_NAME=${HOSTNAME}
COMMAND=''
SSH_DIRECTORY="~/.ssh/github_keys/"

source /srv/developer-server/scripts/functions.sh
source /etc/environment

# Parse the command-line options
while getopts "hc:" opt; do
    case $opt in
        h|--help)
            show_usage
            exit 0
            ;;
        c|--command)
            COMMAND=$OPTARG
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

if [ -z "$COMMAND" ]; then
    echo "Error: The -c or --command option is mandatory."
    show_usage
    exit 1
fi

