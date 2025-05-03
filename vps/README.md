# Simple Guide: Inital Linux Server Setup Step

These steps will help you create a secure way accessz and manage your server.

---
## Step 1: Connection to Your Server via SSH

- Open your terminal, and user `ssh` command:

```bash
ssh USER@SERVER_IP_ADDRESS
```

**Note**
- Replace `USER` for username provided (`root`,`opc`,`ubuntu`,...)
- Replace `SERVER_IP_ADDRESS` with the IP address of your server.
- You will likely be asked to accedt the server's key (type `yes` and press Enter)
- You will then be prompted for the password for `USER`. Enter it carefully (you won't see the characters as you type)

If successful, you will see the server's command prompt

---
## Step 2: Create a New User

It's best practice not to use the `root` user for daily tasks.

- Use the `adduser` command:

```bash
sudo adduser luis122448
```

- Follow the prompts
  - Enter and confirm a strong password for the new user
  - You can press Enter to skip the full name and other optional information
  - Finally, confirm the information by typing `Y`

---
## Step 3: Grant Sudo Access to the New User

- Add the new user to the `sudo` group

```bash
sudo usermod -aG sudo luis122448
```

---
## Step 4: Allow Remote Connection for the New User & Generate SSH Keys

On your local computer (client machine)

- Generate an SSH key pair

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

- Test SSH Key Login

```bash
ssh USER@SERVER_IP_ADDRESS
```

**Note**
- You should be asked for the passphared for your SSH key (if you set one), but not the password for the user on the server.

---
## Step 5: Disable Password Authentication for SSH

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

## Step 6: Final Verification

- Keep your current SSH sessions open.
- Open a new terminal or SSH client window on your local machine.
- Try to login using only the password for your new user.
  
```bash
ssh USER@SERVER_IP_ADDRESS
```

- If you are prompted for a password instead of a key passphrase (or if it just says "Permission denied"), password authentication is disabled successfully.

- Now, the only way to log in via SSH in using your SSH key.

# Extra: Change the Hostname

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