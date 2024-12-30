#!/bin/bash

# Define the variables
VERSION=1.0.0
COMMAND=''
CONFIG_FILE='/srv/developer-server/config/inventory.ini'

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, --command Specify the command to run on the remote servers."
    exit 0
}

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

if [ -z "$COMMAND" ]; then
    echo "Error: The -c or --command option is mandatory."
    show_usage
    exit 1
fi

ansible -i $CONFIG_FILE servers -m $COMMAND

