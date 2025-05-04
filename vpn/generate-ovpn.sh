#!/bin/bash
set -euxo pipefail

if [[ -z "${1-}" ]]; then
  echo "Uso: $0 <nombre_cliente>"
  exit 1
fi
CLIENT="$1"

EASYRSA_DIR=/etc/easy-rsa
PKI_DIR="$EASYRSA_DIR/pki"
OUT_DIR=/etc/openvpn/client

cd "$EASYRSA_DIR"

# (Opcional) inicializar PKI la primera vez:
# bash ./easyrsa init-pki

# 1) Construye el certificado + clave sin passphrase
bash ./easyrsa --batch build-client-full "$CLIENT" nopass

# 2) Monta el .ovpn
cat /etc/openvpn/client-common.txt \
  <(echo -e '<ca>') \
  "$PKI_DIR/ca.crt" \
  <(echo -e '</ca>\n<cert>') \
  "$PKI_DIR/issued/$CLIENT.crt" \
  <(echo -e '</cert>\n<key>') \
  "$PKI_DIR/private/$CLIENT.key" \
  <(echo -e '</key>\n<tls-crypt>') \
  /etc/openvpn/tls-crypt.key \
  <(echo -e '</</tls-crypt>') \
  > "$OUT_DIR/$CLIENT.ovpn"

chmod 644 "$OUT_DIR/$CLIENT.ovpn"

echo "✅ Cliente '$CLIENT' creado en $OUT_DIR/$CLIENT.ovpn"
