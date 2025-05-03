#!/bin/bash

CLIENT="$1"
# Ajusta la ruta del PKI según la estructura de EasyRSA 3.x
PKI="/tmp/easy-rsa/pki"

# Ir al directorio de EasyRSA para ejecutar los comandos
cd /root/easy-rsa

# Generar el certificado y clave para el cliente
./easyrsa --batch build-client-full "$CLIENT" nopass

# Concatenar los archivos necesarios para crear el archivo .ovpn del cliente
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

# Establecer permisos de lectura para el archivo .ovpn
chmod 644 /etc/openvpn/client/"$CLIENT".ovpn
