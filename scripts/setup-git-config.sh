#!/bin/bash

source /etc/environment

# Get the Safe directory
git config --global --add safe.directory /srv/developer-server

# Configure the user
git config --global user.email "luis122448@gmail.com"
git config --global user.name "luis122448"

# Update the origin
git remote remove origin
git remote add origin git@github.com:luis122448/developer-server.git