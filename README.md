![Logo del Projecto](./resources/logo.png)

# Automated Developer Server Setup

This project is designed to manage reserved and static IPs for the development server. 
Follow the steps below to configure your server and execute the script.

---
## Prerequisites

- Install OpenSSH Server:

```bash
sudo apt update
sudo apt install openssh-server
```

- Start the OpenSSH service:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

- Verify the status of the OpenSSH service:

```bash
sudo systemctl status ssh
```

---
## Installation

### Step 1: Define environment variables

Then, define the environment variables in `/etc/environment`:

```bash
sudo nano /etc/environment
```

Add the following variables to the file:

```bash
SERVER_LOCAL_IP=
SERVER_LOCAL_USER=
```

**Important:** Variables defined in `/etc/environment` it used by send script to send files to the server.

### Step 2: Clone the Repository

Use the following command to navigate to the `/srv` directory:

```bash
cd /srv
```

Change the permissions of the `/srv` directory:

```bash
sudo chown -R $USER:$USER /srv
```

Clone the repository to your local machine:

```bash
git clone https://github.com/luis122448/developer-server.git
```

### Step 3: Check the Configuration File

The configuration file is located at `./config/config.ini.` Use the following command to review it:

```bash
cat ./config/config.ini
``` 

Ensure your hostname is listed in the configuration file. If it's not present, add it using the following format:

```yml
[server-001]
IP=192.168.100.199
MAC=
```

**IP:** The reserved IP address for the server.
**MAC:** Always leave this field empty. (It's automatically filled by the script.)

### Step 4: Verify the Hostname

Run the following command to check your current hostname:

```bash
hostnamectl
```

Change the hostname only if it's different from the one listed in the configuration file `./config/config.ini`.

```bash
# Edit the /etc/hostname file:
sudo nano /etc/hostname
# Edit the /etc/hosts file:
sudo nano /etc/hosts
# Reboot the system for the changes to take effect:
sudo reboot
```

### Step 5: Static IP Address Configuration

Evaluate the network interface of the server using the following command:

```bash
ip addr show
```

Execute the script using the following command:

```bash
sudo bash ./start.sh -i *** -g 192.168.***.1
```

**Interface:** The network interface of the server. (e.g., `eth0`, `wlan0`, `enp0s3`, etc.)
**Gateway:** The gateway IP address of the network.

The script will automatically assign the reserved IP to the server and update the configuration file with the MAC address.

**Verification** Run the following command to verify the IP address:

```bash
bash ./scripts/verify.sh -i ***
```

---
## Server Management with Ansible ( In Master Machine )

- Configure SSH Key Authentication (Initial Setup)

```bash
ansible-playbook -i ./config/inventory.ini ./ansible/init_ssh.yml --ask-pass --ask-become-pass --limit $GROUP1
```

**Important** Need add `localhost` an `known_hosts` in local machine

```bash
ssh localhost
```

- Check Server Connectivity

```bash
# Target all hosts defined in the inventory
ansible -i ./config/inventory.ini all -m ping 

# Target a specific host or group (replace '$GROUP1')
ansible -i ./config/inventory.ini $GROUP1 -m ping
```

- Install Docker
  
```bash
ansible-playbook -i ./config/inventory.ini ./ansible/install_docker.yml --ask-become-pass --limit $GROUP1
```

- Open Firewall Port (UFW)
```bash
ansible-playbook -i ./config/inventory.ini ./ansible/ufw_open_port.yml --ask-become-pass -e "ufw_open_port=8080" --limit $GROUP1
```

- Shutdown Servers
  
**⚠️ Warning**: Be very careful with this command. Always use `--limit` to avoid accidentally shutting down unintended server.
  
```bash
# Shutdown a SINGLE specific host (replace 'hostname')
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown_servers.yml --ask-become-pass --limit hostname

# Shutdown all hosts in a specific GROUP (replace 'groupname')
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown_servers.yml --ask-become-pass --limit groupname

# Shutdown MULTIPLE specific hosts/groups (comma-separated, no spaces)
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown_servers.yml --ask-become-pass --limit host1,host2,groupname
```
