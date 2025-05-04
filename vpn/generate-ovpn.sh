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

# 0) Comprueba si ya existe el .ovpn
if [ -f "$PKI_DIR/issued/$CLIENT.crt" ] && [ -f "$PKI_DIR/private/$CLIENT.key" ]; then
    echo "⚠️  Certificado y clave ya existen — ignorando."
else
    cd "$EASYRSA_DIR"
    bash ./easyrsa --batch build-client-full "$CLIENT" nopass
    echo "✅ Certificado y clave generados para el cliente '$CLIENT'."
fi

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
  <(echo -e '</tls-crypt>') \
  > "$OUT_DIR/$CLIENT.ovpn"

chmod 644 "$OUT_DIR/$CLIENT.ovpn"

echo "✅ Cliente '$CLIENT' creado en $OUT_DIR/$CLIENT.ovpn"
