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

# 0) Check if certificate already exists
if [ -f "$PKI_DIR/issued/$CLIENT.crt" ]; then
    echo "⚠️  Certificate for '$CLIENT' already exists."
    exit 1
fi

cd "$EASYRSA_DIR"

# Generate request and key WITHOUT password first (temporarily) for automation ease,
# then encrypt it. 
# The most robust way without installing 'expect' is to generate without pass and then encrypt the key with openssl.

# 1. Generate cert + key (without password temporarily)
bash ./easyrsa --batch build-client-full "$CLIENT" nopass

# 2. Encrypt the private key with the provided password
#    Overwrite the original key with the encrypted version (AES-256)
openssl rsa -aes256 -in "$PKI_DIR/private/$CLIENT.key" -out "$PKI_DIR/private/$CLIENT.key.enc" -passout pass:"$PASS"
mv "$PKI_DIR/private/$CLIENT.key.enc" "$PKI_DIR/private/$CLIENT.key"

echo "✅ Private key encrypted for client '$CLIENT'."

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
