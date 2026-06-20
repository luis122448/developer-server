# Developer Server — Homelab & Internal Services

Repository of the tools and services deployed on the development server,
used mainly on the **local network** (some also reachable over the public web).

> **Scope:** This repo covers the internal services (Docker) and the server
> infrastructure automation. The public-exposure layer (FRP, Kubernetes, Ingress,
> certificates) lives in `/srv/kubernetes-server`.

---

## Repository structure

| Directory         | Purpose                                                          |
| ----------------- | ---------------------------------------------------------------- |
| `docker/`         | Services deployed with Docker Compose (one per subdirectory)     |
| `ansible/`        | Server provisioning playbooks (SSH, Docker, UFW, power)          |
| `vpn/`            | OpenVPN client generation and deployment                         |
| `vps/`            | Notes and keys for external VPS (AWS, etc.)                      |
| `ssh/`            | SSH configuration notes                                          |
| `docs/`           | Reference guides (nmap, ansible, Windows machines)               |
| `config/`         | Ansible inventory, reserved IPs, base configuration              |
| `scripts/`        | Support scripts (git, ssh, functions)                            |

---

## Deployed services (`docker/`)

Each service has its own `docker-compose.yml` and a `*-readme.md` with details.
Access is via `http://<server-IP>:<port>` unless stated otherwise.

### 🛠️ Development

| Service            | Port   | Description                          |
| ------------------ | ------ | ------------------------------------ |
| `code-server`      | 8004   | VS Code in the browser               |
| `code-server-lite` | 8010   | Lightweight / ephemeral VS Code      |
| `registry`         | 5000   | Private Docker registry              |
| `portainer`        | 9000   | Docker container management/inventory (central) |
| `portainer-agent`  | 9001   | Agent to deploy on each VM for central inventory |

### 🌐 Network / Access

| Service  | Access         | Description                                       |
| -------- | -------------- | ------------------------------------------------- |
| `adguard`| 53 / 3000      | Network-wide DNS with ad/tracker blocking         |
| `speedtest-tracker` | 8002 | Internet speed monitoring with history        |
| `windows`| 1688           | KMS activation server (vlmcsd) for Windows/Office |
| `proxy`  | nginx configs  | Reverse proxy (not a compose, just `.conf` files) |
| `ssl`    | nginx configs  | TLS / domain configuration (`.conf`)              |
| `frp`    | `frpc.toml`    | FRP tunnel client toward the public server        |

### 📄 Productivity / Office

| Service       | Port      | Description                       |
| ------------- | --------- | --------------------------------- |
| `nextcloud`   | host net  | NAS / file storage                |
| `onlyoffice`  | 8008      | Online document editing           |
| `trilium`     | 8009      | Hierarchical notes                |
| `stirling-pdf`| 8007      | PDF utilities                     |

### 🎬 Media / Personal

| Service       | Port                | Description                          |
| ------------- | ------------------- | ------------------------------------ |
| `plex`        | host net            | Media server                         |
| `navidrome`   | 8003                | Music server                         |
| `invidious`   | 8006                | Alternative YouTube frontend         |
| `immich`      | 2283                | Photo management                     |
| `arr`         | 9696/8989/7878/6767 | *arr stack (prowlarr/sonarr/radarr/bazarr) |
| `qbittorrent` | host net            | Torrent client                       |
| `webtop`      | 4500                | Linux desktop in the browser         |
| `brave`       | 8005                | Brave browser in the browser         |

> Start a service: `cd docker/<service> && docker compose up -d`

---

## Server provisioning

This section sets up a new server: reserved static IP + management via Ansible.

### Prerequisites — OpenSSH Server

<details>
<summary>Ubuntu</summary>

```bash
sudo apt update
sudo apt install openssh-server
sudo systemctl enable --now ssh
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo pacman -Syu
sudo pacman -S openssh
sudo systemctl enable --now sshd
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo yum install openssh-server
sudo systemctl enable --now sshd
```

</details>

Generate an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096
```

### Step 1 — Clone the repository

```bash
cd /srv
sudo chown -R $USER:$USER /srv
git clone https://github.com/luis122448/developer-server.git
cd developer-server
```

### Step 2 — Configure hostname and IP

1. Check the hostname: `hostnamectl`
2. Edit `config/config.ini` and make sure the hostname and static IP are defined.
   If missing, add the entry (leave `MAC` empty; the script fills it in):

   ```ini
   [your-hostname]
   IP=192.168.100.X
   MAC=
   ```

3. If the system hostname does not match `config.ini`, sync it
   (`/etc/hostname`, `/etc/hosts`) and reboot.

### Step 3 — Assign the static IP

```bash
ip addr show                                          # identify the interface
sudo bash ./start.sh -i <interface> -g <gateway_ip>   # assign the reserved IP
sudo bash ./verify.sh -i <interface>                  # verify
```

---

## Management with Ansible (from the master machine)

**Requirement:** `sshpass`

<details>
<summary>Install sshpass</summary>

```bash
# Ubuntu
sudo apt install sshpass
# Arch
sudo pacman -S sshpass
# Oracle
sudo yum install sshpass
```

</details>

Add the new host to the inventory `config/inventory.ini`:

```ini
[all]
your-hostname ansible_host=192.168.100.107
```

```bash
# Initial SSH key authentication
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./config/inventory.ini ./ansible/init-ssh.yml --ask-pass --ask-become-pass --limit $GROUP1

# Open a firewall port (UFW)
ansible-playbook -i ./config/inventory.ini ./ansible/ufw-open-port.yml --ask-become-pass -e "target_port=8080" --limit $GROUP1

# Install Docker (optional)
ansible-playbook -i ./config/inventory.ini ./ansible/install-docker.yml --ask-become-pass --limit $GROUP1
```

### Connectivity

```bash
ansible -i ./config/inventory.ini all -m ping        # all hosts
ansible -i ./config/inventory.ini $GROUP1 -m ping    # a specific group
```

### Shutting down servers

> **⚠️ Caution:** always use `--limit` to avoid shutting down unintended hosts.

```bash
# A specific host
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit hostname

# A group
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit groupname
```
