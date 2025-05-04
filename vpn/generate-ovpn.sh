#!/bin/bash
set -euxo pipefail

if [[ -z "${1-}" ]]; then
  echo "Usage: $0 <client_name>"
  exit 1
fi
CLIENT="$1"

EASYRSA_DIR=/etc/easy-rsa
PKI_DIR="$EASYRSA_DIR/pki"
OUT_DIR=/etc/openvpn/client

cd "$EASYRSA_DIR"

# Tell Easy-RSA which wrapper is calling vars
export EASYRSA_CALLER="${0##*/}"

# Load Easy-RSA defaults
# (now that EASYRSA_CALLER is defined, this won't explode)
source ./vars

# Build the client cert
bash ./easyrsa --batch build-client-full "$CLIENT" nopass

# Create the .ovpn file by concatenating all parts
cat /etc/openvpn/client-common.txt \
  <(echo -e '<ca>') \
  "$PKI_DIR/ca.crt" \
  <(echo -e '</ca>\n<cert>') \
  "$PKI_DIR/issued/$CLIENT.crt" \
  <(echo -e '</cert>\n<key>') \
  "$PKI_DIR/private/$CLIENT.key" \
  <(echo -e '</key>\n<tls-crypt>') \
  /etc/openvpn/tls-crypt.key \
  <(echo -e '</tls-crypt>') \
  > "$OUT_DIR/$CLIENT.ovpn"

# Set permissions
chmod 644 "$OUT_DIR/$CLIENT.ovpn"

echo "Client '$CLIENT' configuration written to $OUT_DIR/$CLIENT.ovpn"