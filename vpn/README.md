# Install and Configure OpenVPN on Ubuntu 24.04

This guide provides step-by-step instructions to install and configure OpenVPN on Ubuntu 24.04.

---
## Objectives

Automate the configuration of multiple local servers using a VPN hosted on a VPS with a public IP. The goal is to expose local services through the VPN with reverse proxies (e.g., Nginx) while preserving direct local access. Servers can be accessed via their VPN IPs **or** their local network IPs.

---
## Configuration Table Example

| Server        | Local IP         | VPN IP    | MAC Address         | Reserved? |
|---------------|------------------|-----------|---------------------|-----------|
| raspberry-001 | 192.168.100.101  | 10.8.0.11 | d8:3a:dd:f6:05:fb   | [X]       |
| raspberry-002 | 192.168.100.102  | 10.8.0.12 | 2c:cf:67:79:45:46   | [X]       |
| raspberry-003 | 192.168.100.103  | 10.8.0.13 | 2c:cf:67:79:43:c3   | [X]       |
| ... | ...  | ... | ...   | ...      |

---
## Installation

### Update Dependencies

Update the system packages to the latest versions:

```bash
sudo apt update && sudo apt upgrade -y
```

### Install Required Packages

Install OpenVPN:

```bash
sudo apt install openvpn -y
```

Install Ansible:

```bash
sudo apt install ansible -y
```

Install EasyRSA and initialize the working directory:

```bash
sudo apt install easy-rsa
sudo mkdir -p /etc/easy-rsa
sudo chown -R $USER:$USER /etc/easy-rsa
cp -r /usr/share/easy-rsa/* /etc/easy-rsa/
cd /etc/easy-rsa
```

---
## Configure EasyRSA

### Edit the `vars` File

Copy the example `vars` file and edit it to set your organization details:

```bash
cp vars.example vars
nano vars
```

Edit values such as set_var `EASYRSA_REQ_COUNTRY`, `EASYRSA_REQ_PROVINCE`, `EASYRSA_REQ_CITY`, `EASYRSA_REQ_ORG`, `EASYRSA_REQ_EMAIL`, `EASYRSA_REQ_OU`

```bash
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "Copyleft Certificate Co"
set_var EASYRSA_REQ_EMAIL      "me@example.net"
set_var EASYRSA_REQ_OU         "My Organizational Unit"
```

### Generate Keys and Certificates

Run the following commands to initialize and generate the necessary keys and certificates:

```bash
cd /etc/easy-rsa

source vars

bash easyrsa init-pki
bash easyrsa build-ca nopass
bash easyrsa gen-req server nopass
bash easyrsa sign-req server server
bash easyrsa gen-dh
```

Copy Certificates to OpenVPN Directory

``` bash
sudo cp /etc/easy-rsa/pki/ca.crt /etc/openvpn/
sudo cp /etc/easy-rsa/pki/issued/server.crt /etc/openvpn/
sudo cp /etc/easy-rsa/pki/private/server.key /etc/openvpn/
sudo cp /etc/easy-rsa/pki/dh.pem /etc/openvpn/
```

---
## Configure OpenVPN

### Generate `tls-auth.key`

```bash
sudo openvpn --genkey secret /etc/openvpn/tls-crypt.key
```

### Define the OpenVPN Server Configuration

Create ccd directory

```bash
sudo mkdir /etc/openvpn/ccd
```

Create file `/etc/openvpn/server.conf`:

```bash
sudo nano /etc/openvpn/server.conf
```

And write and save

```bash
# OpenVPN server configuration file

# Ip address and port OpenVPN will listen on
port 1194
# Protocol: UDP is generally faster and lower latency than TCP,
# often preferred for performance unless firewalls block UDP
proto udp
dev tun
topology subnet
keepalive 10 120
duplicate-cn

# Newwork address for clients
server 10.8.0.0 255.255.255.0

# Directory for client-specific configuration files
client-config-dir /etc/openvpn/ccd
# ifconfig-pool-persist ipp.txt

# Key and certificate files
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
tls-crypt /etc/openvpn/tls-crypt.key

# Client authentication and network settings
# push "redirect-gateway def1 bypass-dhcp"
# push "route 192.168.100.0 255.255.255.0"
push "route 10.8.0.0 255.255.255.0"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Data compression
allow-compression no

# Enable client capability to automatically initiate connection
user nobody
group nogroup

# Persist key and tun device across restarts
persist-key
persist-tun

# Enable logging of server activity
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
```

---
## Enable IP Forwarding

Edit `/etc/sysctl.conf` to enable IP forwarding:

```bash
    sudo nano /etc/sysctl.conf
```

Uncomment or add the following line:

```bash
    net.ipv4.ip_forward=1
```

Apply the changes:

```bash
    sudo sysctl -p
```

---
## Start and Manage OpenVPN Service

Start and enable the OpenVPN service:

```bash
    sudo systemctl start openvpn@server
    sudo systemctl enable openvpn@server
```

Verify the service status:

```bash
    sudo systemctl status openvpn@server
```

**Note**
    - Look for the line starting with `Active:`
      - If it shows `Active: active (running) since <timestamp>; <duration> ago`, the service service started successfully and is currently operantional.
      - If it shows `Active: inactive (dead)`, the service is not runing.
      - It if shows `Active: failed`, the service attempted to start but encountered an error and stopped.
    - To exit, press `q`

### Debug the Service:

If the service status indicates an issue (inactive, failed) or if clients cannot connect even when the service is running

Using `journalctl` for Systemd Logs:

```bash
    journalctl -xeu openvpn@server
```

Viewing the Main OpenVPN log gile or Status log:

```bash
    sudo cat /var/log/openvpn.log
    sudo cat /var/log/openvpn-status.log
```

After any changes, Restart the service if needed:

```bash
    sudo systemctl restart openvpn@server
```

---
## Generate Client Configuration Files

### Define VPN Host and Port

Set the VPN host and port:

```bash
    export VPN_HOST=***.***.***.***
    export VPN_PORT=1194
```

### Generate Client Configuration Files

Run the Ansible playbook to generate client configuration files:

```bash
sudo chown -R $USER:$USER /etc/easy-rsa
cd /srv/developer-server
ansible-playbook -i ./config/inventory.ini ./vpn/generate-all-clients.yml
```

Verify a sample client configuration file

```bash
cat /etc/openvpn/client/localhost.ovpn 
```

**Note** When viewing the file content, pay attention to the following key parts:
    - `remote $IP $PORT`: Look for the `remote` directive
    - `<ca>`,`<cert>`,`<key>`,`<tls-crypt>` sections

**Important** For reset all configurations files

```bash
sudo rm -rf /etc/openvpn/client/*
```

### Copy and Distribute Configuration Files

Copy the configuration files to your local machine:

```bash
scp <username>@<server_ip>:/etc/openvpn/clients-ovpn.tar.gz /srv/developer-server/vpn
```

Unzip and move the files to the OpenVPN directory:

```bash
mkdir -p /etc/openvpn/client
sudo tar --overwrite -xzvf ./vpn/clients-ovpn.tar.gz -C /etc/openvpn/client
```

Distribute the configuration files to your devices:

```bash
ansible-playbook -i ./config/inventory.ini ./vpn/deploy-ovpn-clients.yml --ask-become-pass
```

---
## Additional Notes

- Ensure that your firewall allows traffic on port `1194/udp`.
- Use `journalctl` and OpenVPN logs for
Distribute the configuration files to your devices:

```bash
    ansible-playbook -i ./config/inventory.ini ./vpn/forward_vpn_ports.yml --ask-become-pass
```