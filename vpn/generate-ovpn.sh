#!/bin/bash

CLIENT="$1"
# Adjust the PKI path according to EasyRSA 3.x structure
PKI="/etc/easy-rsa/pki"

sudo chown -R $USER:$USER /etc/easy-rsa

# Go to the EasyRSA directory to run the commands
cd /etc/easy-rsa

# Generate the certificate and key for the client
source vars

easyrsa --batch build-client-full "$CLIENT" nopass

# Concatenate the necessary files to create the client .ovpn file
cat /etc/openvpn/client-common.txt \
    <(echo -e '<ca>') \
    "$PKI/ca.crt" \
    <(echo -e '</ca>\n<cert>') \
    "$PKI/issued/$CLIENT.crt" \
    <(echo -e '</cert>\n<key>') \
    "$PKI/private/$CLIENT.key" \
    <(echo -e '</key>\n<tls-crypt>') \
    /etc/openvpn/tls-crypt.key \
    <(echo -e '</tls-crypt>') \
    > /etc/openvpn/client/"$CLIENT".ovpn

# Set read permissions for the .ovpn file
chmod 644 /etc/openvpn/client/"$CLIENT".ovpn