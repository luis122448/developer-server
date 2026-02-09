# How to Allow and Configure Ports in `frps.toml`

This guide outlines the steps to configure and allow additional ports for your `frps` (FRP server) instance by modifying the `frps.toml` configuration file and restarting the service. It covers both the ports `frps` listens on and the ports it allows clients to use for forwarding.

## Steps

1.  **Locate and Edit `frps.toml`**:
Open the `frps.toml` file, which is typically located at `/etc/frp/frps.toml` on the server, using your preferred text editor.

```bash
sudo nano /etc/frp/frps.toml
```

2.  **Configure Server Listening Ports and Client Allowed Ports**:
Within the `frps.toml` file, you will define different types of ports:

### a. `frps` Server Listening Ports (e.g., `bindPort`, `vhostHTTPPort`, `vhostHTTPSPort`)
These are the ports that the `frps` server itself listens on for incoming client connections or HTTP/HTTPS traffic. Ensure these are configured to your desired port numbers.

```toml
# frps.toml
[common]
bindPort = 7000          # Port for FRP client connections
# Other common configurations...

# HTTP and HTTPS ports for proxying web services (if enabled)
vhostHTTPPort = 80
vhostHTTPSPort = 443
```

*   `bindPort`: This is the primary port that FRP clients connect to.
*   `vhostHTTPPort`: The HTTP port for VHost (virtual host) proxying, used for web services.
*   `vhostHTTPSPort`: The HTTPS port for VHost proxying, used for secure web services.

### b. `allowPorts` for Client Proxying
This crucial setting defines the range of `remote_port` values that `frps` will permit clients to use when setting up their proxies (e.g., for TCP, UDP, or other custom types). If a client requests a `remote_port` not specified here, `frps` will reject the connection.

Add or modify the `allowPorts` array within the `[common]` section, specifying ranges or individual ports.

```toml
# frps.toml
[common]
# ... (previous configurations like bindPort)

allowPorts = [
    { start = 22, end = 22 },       # Allow clients to forward to remote port 22
    { start = 80, end = 80 },       # Allow clients to forward to remote port 80
    { start = 443, end = 443 },     # Allow clients to forward to remote port 443
    { start = 1521, end = 1521 },   # Example: Allow clients to forward to remote port 1521 (e.g., Oracle DB)
    { start = 6443, end = 6443 },   # Example: Allow clients to forward to remote port 6443 (e.g., Kubernetes API)
    { start = 7500, end = 7500 },
    { start = 8080, end = 8080 },
    { start = 30000, end = 32000 }  # Example: Allow a range of ports for clients
]
```
Ensure that any `remote_port` you configure for a client-side proxy (as shown in the `[ssh_custom]` example below) falls within the `allowPorts` definitions on the server.

### c. Example Client-Side TCP Proxy Configuration (using an allowed `remote_port`)
This is an example of a client-side configuration that would use one of the `allowPorts` defined above. The `remote_port` specified here must be within the `allowPorts` array in `frps.toml`.

```toml
# frpc.toml (Client-side configuration example)
[ssh_custom]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 2222 # This port MUST be allowed in frps.toml's allowPorts
```
**Important**: Ensure that all configured ports are not already in use on your server and are allowed by your server's firewall settings (e.g., `ufw`, `firewalld`, AWS Security Groups, etc.).

3.  **Save Changes**:
After making your modifications, save the `frps.toml` file. If you are using `nano`, press `Ctrl+O`, then `Enter`, and finally `Ctrl+X`.

4.  **Restart the `frps` Service**:
For the changes to take effect, you need to restart the `frps` service. The exact command may vary depending on how you've set up `frps` (e.g., systemd service, Docker container).

**Example (for systemd service)**:

```bash
sudo systemctl daemon-reload
sudo systemctl restart frps
```

**Example (for Docker container)**:
If `frps` is running in a Docker container, you would typically restart the container. First, find the container ID or name:

```bash
docker ps
```

Then restart it:

```bash
docker restart <frps_container_id_or_name>
```

After restarting, your `frps` server should be listening on its configured ports and allowing client proxies on the `allowPorts`. You can verify this by checking the service status or using tools like `netstat` or `ss`.

```bash
sudo systemctl status frps
sudo netstat -tuln | grep <port_number>
```