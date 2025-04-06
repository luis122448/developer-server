#!/bin/bash
CLIENT="$1"

# Generar certificados con EasyRSA
cd /etc/openvpn/easy-rsa
./easyrsa build-client-full "$CLIENT" nopass

# Crear el archivo .ovpn concatenando los archivos necesarios
cat /etc/openvpn/client-common.txt \
    <(echo -e '<ca>') /etc/openvpn/easy-rsa/pki/ca.crt <(echo -e '</ca>\n<cert>') \
    /etc/openvpn/easy-rsa/pki/issued/"$CLIENT".crt <(echo -e '</cert>\n<key>') \
    /etc/openvpn/easy-rsa/pki/private/"$CLIENT".key <(echo -e '</key>\n<tls-auth>') \
    /etc/openvpn/tls-auth.key <(echo -e '</tls-auth>') \
    > /etc/openvpn/client/"$CLIENT".ovpn

# Cambiar permisos del archivo .ovpn
chmod 644 /etc/openvpn/client/"$CLIENT".ovpn