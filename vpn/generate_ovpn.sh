#!/bin/bash
CLIENT="$1"
PKI="/etc/openvpn/easy-rsa/easyrsa3/pki"

# Generar certificados con EasyRSA
cd /etc/openvpn/easy-rsa
./easyrsa build-client-full "$CLIENT" nopass

# Crear el archivo .ovpn concatenando los archivos necesarios
cat /etc/openvpn/client-common.txt \
    <(echo -e '<ca>') "$PKI"/ca.crt <(echo -e '</ca>\n<cert>') \
    "$PKI"/issued/"$CLIENT".crt <(echo -e '</cert>\n<key>') \
    "$PKI"/private/"$CLIENT".key <(echo -e '</key>\n<tls-auth>') \
    /etc/openvpn/tls-auth.key <(echo -e '</tls-auth>') \
    > /etc/openvpn/client/"$CLIENT".ovpn

# Cambiar permisos del archivo .ovpn
chmod 644 /etc/openvpn/client/"$CLIENT".ovpn