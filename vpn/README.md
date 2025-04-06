# Install OpenVPN on Ubuntu 24.04

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
    cd /etc/openvpn
    git clone https://github.com/OpenVPN/easy-rsa.git
    cd easy-rsa/easyrsa3
    ./easyrsa init-pki
    ./easyrsa build-ca nopass
```

Generate `tls-auth.key`

```bash
    openvpn --genkey --secret /etc/openvpn/tls-auth.key
```

Move to directory

```bash
    cd /srv/developer-server
```

Generate a new OpenVPN configuration file:

```bash
    ansible-playbook -i ./config/inventory.ini ./vpn/generate_clients.yml
```

Copy the OpenVPN configuration file to your local machine:

```bash
    scp <username>@<server_ip>:/etc/openvpn/clients_ovpn.tar.gz /srv/developer-server/vpn
```

Unzip the OpenVPN configuration file and move it to the OpenVPN directory:

```bash
    tar -xzvf ./vpn/clients_ovpn.tar.gz
```

Distribute the OpenVPN configuration file to your devices:
```bash
    ansible-playbook -i inventory.ini deploy_ovpn_clients.yml
```

```
