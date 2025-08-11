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
- Replace `SERVER_IP_IP_ADDRESS` with the IP address of your server.
- You will likely be asked to accedt the server's key (type `yes` and press Enter)
- You will then be prompted for the password for `USER`. Enter it carefully (you won't see the characters as you type)

If successful, you will see the server's command prompt

### Create a New User

It is a security best practice to avoid using `root` for regular tasks.

- Use the `adduser` command:

```bash
sudo adduser luis122448
```

- Follow the prompts
  - Enter and confirm a strong password for the new user
  - You can press Enter to skip the full name and other optional information
  - Finally, confirm the information by typing `Y`

### Grant Administrative (Sudo) Privileges

- Add the new user to the `sudo` group

```bash
sudo usermod -aG sudo luis122448
```

**Note:** On some systems like CentOS/RHEL, the group might be `wheel` instead of `sudo`.

### Authorize a Personal SSH Key

To log in without entering your user's password every time, you need to add your local machine's public SSH key to your new user's `authorized_keys` file on the server.

#### Step 1: Ensure You Have an SSH Key

First, check if you have an SSH key pair on your **local machine**. If not, create one:

```bash
# This command creates a new 4096-bit RSA key pair.
ssh-keygen -t rsa -b 4096
```

- When prompted for a file to save the key, press **Enter** to accept the default location (`~/.ssh/id_rsa`).
- **IMPORTANT:** When prompted, enter a strong **passphrase**. This encrypts your private key on your disk, providing a critical layer of security.
- This creates two files in your `~/.ssh/` directory:
  - `id_rsa`: Your private key. **NEVER share this file.**
  - `id_rsa.pub`: Your public key. This is what you will copy to the server.

#### Step 2: Copy Your Public Key to the Server

You have two methods to copy the key. The first one is the easiest.

**Method 1: Using `ssh-copy-id` (Recommended)**

This command automatically handles copying the key and setting the correct permissions on the server.

```bash
# Replace luis122448 and SERVER_IP_ADDRESS accordingly.
ssh-copy-id luis122448@SERVER_IP_ADDRESS
```

- You will be prompted for the password for `luis122448` on the server one last time.
- The command will copy the key from `~/.ssh/id_rsa.pub` by default.

**Method 2: Manual Key Copy**

If `ssh-copy-id` is not available or fails, you can add the key manually.

1.  **Display your public key** on your local machine and copy it to your clipboard:

```bash
cat ~/.ssh/id_rsa.pub
```

The output will be a single long string starting with `ssh-rsa ...`.

2.  **Log in to the server** as your new user with the password:

```bash
ssh luis122448@SERVER_IP_ADDRESS
```

3.  **On the server**, create the `.ssh` directory and the `authorized_keys` file with the correct permissions:
    
```bash
# Create the directory if it doesn't exist
mkdir -p ~/.ssh

# Append your copied public key to the file.
# Paste your key inside the quotes.
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys

# Set strict permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

- **CRITICAL**: Use the double arrow `>>` to append. A single `>` will overwrite the file.
- After running `echo`, you can log out of the server with `exit`.

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

Follow these steps if you are starting with a private key file (e.g., `server-key.pem`). The goal is to create a new user and authorize the same key for them, ensuring a consistent setup for automation.

### Initial Login

- First, ensure your private key file has the correct permissions. It must not be publicly viewable.

```bash
chmod 400 ./vps/keys/server-key.pem
```

- Connect to the server using the provided initial user (e.g., `ubuntu`) and your key

```bash
ssh -i "./vps/keys/server-key.pem" USER@SERVER_IP_ADDRESS
```

### Create a New User

Once logged in, create the new user for your tasks.

```bash
sudo adduser luis122448
```

- Follow the prompts
  - Enter and confirm a strong password for the new user
  - You can press Enter to skip the full name and other optional information
  - Finally, confirm the information by typing `Y`

### Grant Sudo Access to the New User

- Add the new user to the `sudo` group

```bash
sudo usermod -aG sudo luis122448
```

**Note:** On some systems like CentOS/RHEL, the group might be `wheel` instead of `sudo`.

### Authorize the Initial SSH Key

This ensures that automation scripts using the initial key (`server-key.pem`) will work for the new user.

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
ssh -i "./vps/keys/server-key.pem" luis122448@SERVER_IP_ADDRESS
```

### Authorize a Personal SSH Key

While the initial server key (`server-key.pem`) works, you will likely want to log in using your own personal SSH key (`~/.ssh/id_rsa`) for convenience. This avoids having to specify the `-i` flag for every command.

This process is the manual equivalent of `ssh-copy-id`.

1.  **Get your public key** on your **local machine**.

```bash
cat ~/.ssh/id_rsa.pub
```

Copy the entire output string to your clipboard. It starts with `ssh-rsa AAAA...`. If you don't have this file, see the instructions in "Scenario A" to generate one.

2.  **Connect to the server** using the initial key that already works:
    
```bash
ssh -i "./vps/keys/server-key.pem" luis122448@SERVER_IP_ADDRESS
```

3.  **On the server**, append your personal public key to the `authorized_keys` file:

```bash
# CRITICAL: Use the append operator (>>) to avoid overwriting the existing key.
# Using a single (>) would remove access for the initial key.
echo "PASTE_YOUR_COPIED_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
```

- Paste the key you copied from your local machine inside the quotes.
- The permissions on the `~/.ssh` directory and `authorized_keys` file should already be correct from the previous steps, so you don't need to set them again.

1.  **Log out** of the server (`exit`).

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