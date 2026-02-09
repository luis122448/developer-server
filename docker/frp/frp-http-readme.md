# FRP Guide: HTTP/HTTPS Forwarding for Local Web Services

This guide provides a step-by-step walkthrough for configuring FRP (Fast Reverse Proxy) to expose local web services (e.g., running in sudo Docker containers) to the internet through a remote server (VPS).

This approach uses FRP's built-in HTTP and HTTPS proxy capabilities, which is ideal for web applications.

**Architecture:**
*   **FRP Server (frps):** Installed on a VPS with a public IP address.
*   **FRP Client (frpc):** Installed on a local machine (e.g., a home server) where the web service is running.
*   **Service to Expose:** A web application, for example, running inside a sudo Docker container on the local machine.

**FRP Version:** `v0.62.1`

**Official FRP Documentation:** [https://github.com/fatedier/frp](https://github.com/fatedier/frp)

---
## Part 1: FRP Server (`frps`) Setup on the VPS

This section covers the installation and configuration of the `frps` component on your remote server.

### 1.1. Download and Install `frps`

- Connect to your VPS via SSH:

```bash
ssh your_user@your_vps_public_ip
```

- Create the necessary directories:
  
```bash
sudo mkdir -p /etc/frp
```

- Download the appropriate FRP release for your VPS architecture (most modern VPS use `linux_amd64`):
  
```bash
FRP_VERSION="0.62.1"
FRP_ARCH="amd64"
wget "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz"
tar -zxvf "frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz"
sudo mv "frp_${FRP_VERSION}_linux_${FRP_ARCH}/frps" /usr/local/bin/frps
```

- Clean up the downloaded files:
  
```bash
rm -rf "frp_${FRP_VERSION}_linux_${FRP_ARCH}" "frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz"
```

- Ensure `frps` has the necessary permissions to bind to low-numbered ports (like 80 and 443):

```bash
sudo setcap cap_net_bind_service=+ep /usr/local/bin/frps
```

### 1.2. Configure `frps.toml`

The `frps.toml` file contains the server's configuration.

- Generate random Token for authentication (you can use any secure method to generate a token):
  
```bash
openssl rand -hex 32
```

- Create and edit the configuration file:
  
```bash
sudo mkdir -p /etc/frp
sudo nano /etc/frp/frps.toml
```

- Paste the following configuration. **You must set a secure token.**
  
```toml
# Port for frpc clients to connect
bindPort = 7000

# Ports for the web services you will expose
# frps will listen on these ports for public traffic
vhostHTTPPort = 80
vhostHTTPSPort = 443

# FRP Dashboard (Optional, but recommended for monitoring)
webServer.port = 7500
webServer.user = "your_dashboard_user"
webServer.password = "your_secure_password"
webServer.addr = "0.0.0.0"

# Authentication
# IMPORTANT: Generate a long, secret token for security
[auth]
token = "YOUR_VERY_SECRET_TOKEN"
```

> **To generate a secure token**, you can use: `openssl rand -hex 32`

### 1.3. Set up `frps` as a `systemd` Service

This ensures `frps` runs automatically in the background.

- Create the service file:
  
```bash
sudo nano /etc/systemd/system/frps.service
```

- Paste the following content:
  
```ini
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.toml

[Install]
WantedBy=multi-user.target
```

- Enable and start the service:
  
```bash
sudo systemctl daemon-reload
sudo systemctl enable frps
sudo systemctl start frps
```

- Check that the service is running correctly:
  
```bash
# You should see "Active: active (running)"
sudo systemctl status frps

# To follow the logs in real-time
sudo journalctl -u frps -f
```

### 1.4. Configure the Firewall

Open the necessary ports on your VPS firewall (e.g., `ufw`).

```bash
sudo ufw allow 7000/tcp  # For frpc connections
sudo ufw allow 80/tcp   # For HTTP traffic
sudo ufw allow 443/tcp  # For HTTPS traffic
sudo ufw allow 7500/tcp # For the FRP dashboard
sudo ufw enable
sudo ufw status
```

---
## Part 2: FRP Client (`frpc`) Setup on the Local Machine

This section covers the setup of `frpc` on the machine where your web service is running. We will use sudo Docker for a clean and containerized setup.

### 2.1. Prepare the `frpc.toml` Configuration

Create a directory on your local machine to store the `frpc` configuration.

```bash
sudo mkdir -p /etc/frp/frpc-config
sudo nano /etc/frp/frpc-config/frpc.toml
```

- Paste and edit the following configuration:
  
```toml
# Connect to your frps server
serverAddr = "your_vps_public_ip"
serverPort = 7000

[auth]
token = "YOUR_VERY_SECRET_TOKEN"

# ---
# Example 1: Exposing a local HTTP service
# This proxy forwards traffic from http://your-domain.com to a local service
[[proxies]]
name = "my-web-app-http"
type = "http"
localIP = "127.0.0.1" # IP of your local web service
localPort = 8080
customDomains = ["app.your-domain.com"]

# ---
# Example 2: Exposing a local HTTPS service
# This proxy forwards traffic from https://your-domain.com.
# IMPORTANT: This requires frps to handle the TLS certificate.
# For more advanced setups (like wildcard certs), consider a TCP proxy.
[[proxies]]
name = "my-web-app-https"
type = "https"
localIP = "127.0.0.1" # IP of your local web service
localPort = 8443
customDomains = ["app.your-domain.com"]
```
  
**Note on `localIP`**:
- If your web service is a sudo Docker container on the same machine, you can often use the sudo Docker host's IP or the container's specific IP address.
- If the service is just running on the host, you can use `127.0.0.1`.

### 2.2. Run `frpc` using Docker

Running `frpc` in a sudo Docker container is a clean and recommended method.

```bash
sudo docker run --restart=always --network=host -d \
  -v /etc/frp/frpc-config/frpc.toml:/etc/frp/frpc.toml \
  --name frpc-client \
  fatedier/frpc:v0.62.1 \
  -c /etc/frp/frpc.toml
```
**Explanation:**
*   `--restart=always`: Ensures the `frpc` client automatically restarts if it stops.
*   `--network=host`: Allows `frpc` to easily connect to services running on the host machine or other sudo Docker containers.
*   `-d`: Runs the container in detached mode.
*   `-v`: Mounts your local configuration file into the container.
*   `--name`: Gives the container a recognizable name.

- To check the logs and ensure it connected successfully:
  
```bash
sudo docker logs -f frpc-client
# Look for a "login to server success" message.
```

---
## Part 3: DNS Configuration

For your `customDomains` to work, you must point them to your VPS's public IP address.

- **In your DNS provider's dashboard**, create an `A` record:
  - **Name/Host:** `app` (or whatever subdomain you chose)
  - **Value/Points to:** `your_vps_public_ip`

You can use `ping app.your-domain.com` to check if the DNS has updated.

---
## Part 4: Final Access Test

Once `frps`, `frpc`, and your DNS are all configured, you can access your local web service from the internet.

Open your web browser and navigate to:

`http://app.your-domain.com`

or

`https://app.your-domain.com`

The request will travel from your browser to your VPS, through the FRP tunnel, to your local machine, and finally to your web service.
