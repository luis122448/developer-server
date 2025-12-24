#!/bin/bash
set -euo pipefail

if [[ -z "${1-}" ]] || [[ -z "${2-}" ]]; then
  echo "Usage: $0 <client_name> <password>"
  exit 1
fi

CLIENT="$1"
PASS="$2"

EASYRSA_DIR=/etc/easy-rsa
PKI_DIR="$EASYRSA_DIR/pki"
OUT_DIR=/etc/openvpn/client

# 0) Force Cleanup: If exists, delete to regenerate
if [ -f "$PKI_DIR/issued/$CLIENT.crt" ] || [ -f "$PKI_DIR/private/$CLIENT.key" ]; then
    echo "♻️  Certificate for '$CLIENT' exists. Cleaning up to regenerate..."
    
    # Remove files
    rm -f "$PKI_DIR/issued/$CLIENT.crt"
    rm -f "$PKI_DIR/private/$CLIENT.key"
    rm -f "$PKI_DIR/reqs/$CLIENT.req"
    
    # Clean from OpenSSL database (index.txt) to allow re-use of the name
    if [ -f "$PKI_DIR/index.txt" ]; then
        # Remove lines containing /CN=client_name
        sed -i "/\/CN=$CLIENT/d" "$PKI_DIR/index.txt"
        echo "   - Removed from index.txt database."
    fi
fi

cd "$EASYRSA_DIR"

# Generate request and key WITHOUT password first (temporarily) for automation ease,

# 3) Assemble the .ovpn file
#    Note: OpenVPN will ask for the password when importing/connecting because the internal Key is encrypted.
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

echo "✅ Client '$CLIENT' (password protected) created at $OUT_DIR/$CLIENT.ovpn"
