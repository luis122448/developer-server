# Install OpenVPN and on Ubuntu 24.04

## Installation

Update dependencies:

```bash
    sudo apt update && sudo apt upgrade -y
```

Install OpenVPN:

```bash
    sudo apt install openvpn -y
```

Install Ansible:

```bash
    sudo apt install ansible -y
```

Ini EasyRSA

```bash
    sudo apt install easy-rsa
    mkdir ~/easy-rsa
    cp -r /usr/share/easy-rsa/* ~/easy-rsa/
    cd ~/easy-rsa
```

Edit file vars

``` bash
    cp vars.example vars
    nano vars

export KEY_COUNTRY="US"
export KEY_PROVINCE="California"
export KEY_CITY="San Francisco"
export KEY_ORG="MyOrg"
export KEY_EMAIL="youremail@example.com"
export KEY_OU="MyOrgUnit"
```

Generate key and certificates

```bash
    source vars
    bash easyrsa init-pki
    bash easyrsa build-ca
    bash easyrsa gen-req server nopass
    bash easyrsa sign-req server server
    bash easyrsa gen-dh
```

Copy certificates
``` bash
    sudo cp ~/easy-rsa/pki/ca.crt /etc/openvpn/
    sudo cp ~/easy-rsa/pki/issued/server.crt /etc/openvpn/
    sudo cp ~/easy-rsa/pki/private/server.key /etc/openvpn/
    sudo cp ~/easy-rsa/pki/dh.pem /etc/openvpn/
```

Generate `tls-auth.key`

```bash
    openvpn --genkey secret /etc/openvpn/tls-crypt.key
```

Finally, define `/etc/openvpn/server.conf`

```bash
# OpenVPN server configuration file

# Dirección IP y puerto en el que OpenVPN escuchará
port 1194
proto udp
dev tun

# Dirección de red para los clientes
server 10.8.0.0 255.255.255.0

# Dirección IP del servidor VPN
client-config-dir /etc/openvpn/ccd
# ifconfig-pool-persist ipp.txt

# Archivos de clave y certificado
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
tls-crypt /etc/openvpn/tls-crypt.key

# Autenticación de clientes
# push "redirect-gateway def1 bypass-dhcp"
push "route 192.168.100.0 255.255.255.0"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Compresión de datos
allow-compression no

# Habilitar la capacidad de cliente para iniciar conexión automáticamente
user nobody
group nogroup

# Habilitar reenvío de IP
persist-key
persist-tun

# Activar registro de la actividad del servidor
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
```

Habilite resent ports

```bash
    sudo nano /etc/sysctl.conf
    net.ipv4.ip_forward=1
    sudo sysctl -p
```

Start and enable service

```bash
    sudo systemctl start openvpn@server
    sudo systemctl enable openvpn@server
```

Verify Status

```bash
    sudo systemctl status openvpn@server
```

Restart service

```bash
    sudo systemctl restart openvpn@server
```

Debug service

```bash
    journalctl -xeu openvpn@server
```

```bash
    cat /var/log/openvpn-status.log
```

## Generate Config files for Servers

First, Define `VPN_HOST` and `VPN_PORT`

```bash
    export VPN_HOST=***.***.***.***
    export VPN_PORT=1194
```

Generate a new OpenVPN configuration file:

```bash
    cd /srv/developer-server
    ansible-playbook -i ./config/inventory.ini ./vpn/generate_clients.yml
```

Copy the OpenVPN configuration file to your local machine:

```bash
    scp <username>@<server_ip>:/etc/openvpn/clients_ovpn.tar.gz /srv/developer-server/vpn
```

Unzip the OpenVPN configuration file and move it to the OpenVPN directory:

```bash
    mkdir -p /etc/openvpn/client
    sudo tar --overwrite -xzvf ./vpn/clients_ovpn.tar.gz -C /etc/openvpn/client
```

Distribute the OpenVPN configuration file to your devices:

```bash
    ansible-playbook -i ./config/inventory.ini ./vpn/deploy_ovpn_clients.yml --ask-become-pass
```