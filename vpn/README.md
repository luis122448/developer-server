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

Generate a new OpenVPN configuration file:

```bash
    ansible-playbook -i inventory.ini generate_clients.yml
```

Zip and copy the OpenVPN configuration file to your local machine:

```bash
    zip -r client.ovpn.zip /etc/openvpn/clients
```

Copy the OpenVPN configuration file to your local machine:

```bash
    scp <username>@<server_ip>:/etc/openvpn/clients/client.ovpn.zip .
```

Unzip the OpenVPN configuration file and move it to the OpenVPN directory:

```bash
    mkdir -p ~/openvpn
    mv client.ovpn.zip ~/openvpn
    cd ~/openvpn
    unzip client.ovpn.zip
```

Distribute the OpenVPN configuration file to your devices:
```bash
    ansible-playbook -i inventory.ini deploy_ovpn_clients.yml
```

```
