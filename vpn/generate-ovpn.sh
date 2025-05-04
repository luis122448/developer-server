#!/bin/bash
set -euxo pipefail

# 1) Validación de parámetros
if [[ -z "${1-}" ]]; then
  echo "Uso: $0 <nombre_cliente>"
  exit 1
fi
CLIENT="$1"

# 2) Definición de rutas
EASYRSA_DIR="/etc/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"
OUT_DIR="/etc/openvpn/client"

# 3) Entrar en el directorio de Easy-RSA
cd "$EASYRSA_DIR"

# 4) Cargar configuración de Easy-RSA
#    Definimos EASYRSA_CALLER para que vars no falle
export EASYRSA_CALLER="${0##*/}"
source ./vars

# 5) Generar certificado y clave (sin passphrase)
bash ./easyrsa --batch build-client-full "$CLIENT" nopass

# 6) Construir el archivo .ovpn
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

# 7) Ajustar permisos
chmod 644 "$OUT_DIR/$CLIENT.ovpn"

echo "✅ Cliente '$CLIENT' generado en $OUT_DIR/$CLIENT.ovpn"