![Logo del Projecto](./resources/logo.png)

# Automated Developer Server Setup

This project is designed to manage reserved and static IPs for the development server. 
Follow the steps below to configure your server and execute the script.

---
## Prerequisites

- Install OpenSSH Server:

<details>
<summary>Ubuntu</summary>

```bash
sudo apt update
sudo apt install openssh-server
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo pacman -Syu
sudo pacman -S openssh
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo yum install openssh-server
```

</details>

- Start the OpenSSH service:

<details>
<summary>Ubuntu</summary>

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

</details>

- Verify the status of the OpenSSH service:

<details>
<summary>Ubuntu</summary>

```bash
sudo systemctl status ssh
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo systemctl status sshd
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo systemctl status sshd
```

</details>

- Generate an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096
```

---
## Local Machine Setup

### Step 1: Clone the Repository

Navigate to the `/srv` directory, grant permissions, and clone the repository.

```bash
cd /srv
sudo chown -R $USER:$USER /srv
git clone https://github.com/luis122448/developer-server.git
cd developer-server
```

### Step 2: Configure Hostname and IP

1.  **Check your hostname:**

```bash
hostnamectl
```

2.  **Verify `config/config.ini`:** Ensure your server's hostname and desired static IP are correctly defined. If your hostname is not in the file, add a new entry.

```ini
[your-hostname]
IP=192.168.100.X
MAC=
```

*Leave the `MAC` field empty; the script will populate it automatically.*

3.  **Sync your system hostname (if necessary):** If your system's hostname does not match the one in `config.ini`, update it.

```bash
# Edit the following files to match the config.ini hostname
sudo nano /etc/hostname
sudo nano /etc/hosts
# Reboot for changes to take effect
sudo reboot
```

### Step 3: Assign Static IP

1.  **Identify your network interface:**

```bash
ip addr show
```

2.  **Run the setup script:** Replace `<interface>` with your network interface (e.g., `enp0s3`) and `<gateway_ip>` with your network's gateway.

```bash
sudo bash ./start.sh -i <interface> -g <gateway_ip>
```

The script will assign the reserved IP to your server and update the `config.ini` file with the MAC address.

3.  **Verify the configuration:**

```bash
sudo bash ./verify.sh -i <interface>
```

---
## Configure in Server Management with Ansible ( In Master Machine )

**Requirements**: Need install sshpass

<details>
<summary>Ubuntu</summary>

```bash
sudo apt update
sudo apt install sshpass
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo pacman -Syu
sudo pacman -S sshpass
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo yum install sshpass
```

</details>

- Add the new server to your inventory file so Ansible knows it exists. Edit `./config/inventory.ini` and add the new host to the appropriate group (e.g., `[all]`):
- Need SSH keys (e.g., `~/.ssh/id_rsa`):

```ini
[all]
# ... existing servers
your-hostname ansible_host=192.168.100.107 # Use the actual IP of the new server
```

- Configure SSH Key Authentication Login (Initial Setup)

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./config/inventory.ini ./ansible/init-ssh.yml --ask-pass --ask-become-pass --limit $GROUP1
```

- Install and Open Firewall Port (UFW) 

```bash
ansible-playbook -i ./config/inventory.ini ./ansible/ufw-open-port.yml --ask-become-pass -e "port=8080" --limit $GROUP1
```

- Install Docker ( Optional )
  
```bash
ansible-playbook -i ./config/inventory.ini ./ansible/install-docker.yml --ask-become-pass --limit $GROUP1
```

--
## Check Server Connectivity

```bash
# Target all hosts defined in the inventory
ansible -i ./config/inventory.ini all -m ping 

# Target a specific host or group (replace '$GROUP1')
ansible -i ./config/inventory.ini $GROUP1 -m ping
```

--
## Shutdown and Sleep Server

- Shutdown Servers
  
**⚠️ Warning**: Be very careful with this command. Always use `--limit` to avoid accidentally shutting down unintended server.
  
```bash
# Shutdown a SINGLE specific host (replace 'hostname')
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit hostname

# Shutdown all hosts in a specific GROUP (replace 'groupname')
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit groupname

# Shutdown MULTIPLE specific hosts/groups (comma-separated, no spaces)
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit host1,host2,groupname
```