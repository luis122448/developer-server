# Initial Linux Server Setup Guide

This document provides a standardized guide for the initial setup of a new Linux server. The primary goal is to create a non-root user with `sudo` privileges (`luis122448` in this guide) and configure secure SSH access for automation tasks like Ansible playbooks.

---
## Prerequisites

Before you begin, ensure you have the following:

- The server's public IP address ([server_ip]).
- The initial user provided by your host ([initial_user], e.g., `root`, `ubuntu`, `ec2-user`, `opc`).
- Your initial access credentials, which will be either a password or an SSH private key file.

---
## Choose Your Initial Connection Scenario

How you first connect to your server determines the next steps. Choose the scenario that matches your situation:

### Scenario A: Initial Access via Password

- Choose this if your hosting provider gave you a root password but no SSH key.
- Common with many traditional VPS providers (Vultr, DigitalOcean, etc.).

### Scenario B: Initial Access via SSH Key

- Choose this if your hosting provider required you to provide a public key and gave you a private key file (e.g., a `.pem` file) to log in. Password login is typically disabled.
- Common with cloud platforms like AWS, Google Cloud, and Azure.

---
## Scenario A: Initial Access via Password

Follow these steps if you are starting with a password for the `root` or initial user. The goal is to create a new user and switch to more secure key-based authentication.

### Initial Login

Connect to the server using the provided initial user and password.

```bash
ssh -i USER@SERVER_IP_ADDRESS
```

**Note**
- Replace `USER` for username provided (`root`,`opc`,`ubuntu`,...)
- Replace `SERVER_IP_ADDRESS` with the IP address of your server.
- You will likely be asked to accedt the server's key (type `yes` and press Enter)
- You will then be prompted for the password for `USER`. Enter it carefully (you won't see the characters as you type)

If successful, you will see the server's command prompt

### Create a New User

It is a security best practice to avoid using `root` for regular tasks.

- Use the `adduser` command:

```bash
adduser luis122448
```

- Follow the prompts
  - Enter and confirm a strong password for the new user
  - You can press Enter to skip the full name and other optional information
  - Finally, confirm the information by typing `Y`

### Grant Administrative (Sudo) Privileges

- Add the new user to the `sudo` group

```bash
usermod -aG sudo luis122448
```

**Note:** On some systems like CentOS/RHEL, the group might be `wheel` instead of `sudo`.

### Authorize a Personal SSH Key

- If you don't have an SSH key pair, create one on your local machine:

```bash
ssh-keygen -t rsa -b 4096
```

**Note**
- Press Enter when asked for the location unless you have specific need to change it.
- **Set a strong passphrase** when prompted. This adds an extra layer of security to your private key.
- This command creates two files, usually in `~/.ssh/`:
  - `id_rsa` Your private key, **Never Share**
  - `id_rsa.pub` Your public key

- Copy your public key to the server:

```bash
ssh-copy-id USER@SERVER_IP_ADDRESS
```

**Note**
- This command automatically logs into the server and adds your public key (`~/.ssh/id_rsa` by default) to the `authorized_keys` file in your new user's `.ssh` directory on the server.

### Test Key-Based Login

- From a new terminal on your local machine, try to log in as the new user.

```bash
ssh USER@SERVER_IP_ADDRESS
```

**Note**
- You should be asked for the passphared for your SSH key (if you set one), but not the password for the user on the server.

### Disable Password Authentication for SSH

This significantly increases security by preventing brute-force password attacks. Only users with valid SSH keys can log in

- Connect to your server as your new user using your SSH Key.
- Edit the SSH daemon configuration file:

```bash
sudo nano /etc/ssh/sshd_config
```

- Find the line `PasswordAuthentication`:
- Look for a line that says `#PasswordAuthentication yes` or `PasswordAuthentication yes` change it to:

```bash
PasswordAuthentication no
```

- Make sure the `#` (comment symbol) is removed if it was present.
- Save and exit, In `nano` press `Ctrl + X`, then `Y` to confirm saving, then Enter.

- Restart the SSH service to apply the changes

```bash
sudo systemctl restart sshd
```

---
## Scenario B: Initial Access via SSH Key

Follow these steps if you are starting with a private key file (e.g., `developer-key.pem`). The goal is to create a new user and authorize the same key for them, ensuring a consistent setup for automation.

### Initial Login

- First, ensure your private key file has the correct permissions. It must not be publicly viewable.

```bash
chmod 400 ./keys/developer-key.pem
```

- Connect to the server using the provided initial user (e.g., `ubuntu`) and your key

```bash
ssh -i "./keys/developer-key.pem" USER@SERVER_IP_ADDRESS
```

### Create a New User

Once logged in, create the new user for your tasks.

```bash
adduser luis122448
```

- Follow the prompts
  - Enter and confirm a strong password for the new user
  - You can press Enter to skip the full name and other optional information
  - Finally, confirm the information by typing `Y`

### Grant Sudo Access to the New User

- Add the new user to the `sudo` group

```bash
usermod -aG sudo luis122448
```

**Note:** On some systems like CentOS/RHEL, the group might be `wheel` instead of `sudo`.

### Authorize the Initial SSH Key

This ensures that automation scripts using the initial key (`developer-key.pem`) will work for the new user.

```bash
# 1. Create the .ssh directory for the new user
sudo mkdir -p /home/luis122448/.ssh

# 2. Copy the authorized keys file from the initial user to the new user
sudo cp /home/[initial_user]/.ssh/authorized_keys /home/luis122448/.ssh/authorized_keys

# 3. Set the correct ownership for the new user's .ssh directory and its contents
sudo chown -R luis122448:luis122448 /home/luis122448/.ssh

# 4. Set the correct permissions. This is critical for SSH security.
sudo chmod 700 /home/luis122448/.ssh
sudo chmod 600 /home/luis122448/.ssh/authorized_keys
```

### Test the New User Login

Log out of the server. From your local machine, try connecting as luis122448 using the same key.

```bash
ssh -i "./keys/developer-key.pem" luis122448@SERVER_IP_ADDRESS
```

### Authorize a Personal SSH Key

To log in with your personal local key (~/.ssh/id_rsa) instead of always specifying the .pem file, add it as a second authorized key. This is the manual equivalent of ssh-copy-id.

- On your local computer, get your public key's content.

```bash
cat ~/.ssh/id_rsa.pub
```

Copy the entire output string, which starts with ssh-rsa ....

- Connect to the server using a method that already works.

```bash
ssh -i "./keys/developer-key.pem" luis122448@SERVER_IP_ADDRESS
```

- On the server, append your public key to the authorized_keys file.

**CRITICAL:** Use the append operator (`>>`) to avoid overwriting the existing key. Using a single `>` would break access for the `developer-key.pem`.

```bash
echo "ssh-rsa AAAA... your-user@your-local-machine" >> ~/.ssh/authorized_keys
```

### Verify Password Authentication is Disabled

- On cloud servers, this is almost always the default, but it's good practice to verify.

```bash
sudo nano /etc/ssh/sshd_config
```

- Ensure the following line is present and set to no:

```bash
PasswordAuthentication no
```

f you had to make a change, restart the SSH service: `sudo systemctl restart sshd`.

---
## Test All Connections

- Keep your current SSH sessions open.
- Open a new terminal or SSH client window on your local machine.
- Try to login using only the password for your new user.
  
```bash
ssh luis122448@SERVER_IP_ADDRESS
```

- If you are prompted for a password instead of a key passphrase (or if it just says "Permission denied"), password authentication is disabled successfully.

- Now, the only way to log in via SSH in using your SSH key.

---
## Change the Hostname

- Connect to your Server and Use the `hostnamectl` command

```bash
sudo hostnamectl set-hostname server-001
```

- Edit the `/etc/host` file on your server and make sure your new hostname (`server-001`) is listed next to the server local IP address

```bash
sudo nano /etc/hosts
```

- Find the line that looks like `127.0.0.1 localhost` and potentially includes your old hostname.
- Add replace your new hostname `server-001` to the line.

```bash
127.0.0.1 localhost server-001
```

- Verify the change

```bash
hostnamectl
```
- Yo can also user the simpler `hostname` command:

```bash
hostname
```

---
### Configure a Basic Firewall (UFW for Ubuntu/Debian)

- A firewall is essential for blocking unauthorized traffic.

```bash
# Allow SSH connections, otherwise you will be locked out!
sudo ufw allow OpenSSH

# Enable the firewall
sudo ufw enable

# Check the status
sudo ufw status
```