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

# 0) Check if .ovpn already exists
if [ -f "$PKI_DIR/issued/$CLIENT.crt" ] && [ -f "$PKI_DIR/private/$CLIENT.key" ]; then
    echo "⚠️  Certificate and key already exist — skipping."
else
    cd "$EASYRSA_DIR"
    bash ./easyrsa --batch build-client-full "$CLIENT" nopass
    echo "✅ Certificate and key generated for client '$CLIENT'."
fi

# 2) Assemble the .ovpn file
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

chmod 644 "$OUT_DIR/$CLIENT.ovpn"

echo "✅ Client '$CLIENT' created at $OUT_DIR/$CLIENT.ovpn"
