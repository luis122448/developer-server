# How to Update FRPS Server Configuration

This guide explains the necessary steps to update the configuration of your `frps` (FRP Server) running on a remote VPS, for example, to allow new ports for your proxies.

## Step 1: Modify the Local `frps.toml` File

First, edit the `frp/frps.toml` file in this repository. If you need to allow new remote ports for your proxies, add or update the top-level `allowPorts` directive.

**Important:** The `allowPorts` directive should be at the top level of the configuration file, **not** inside the `[auth]` section.

**Example:**
```toml
bindPort = 7000

# Add all the ports or port ranges you need to expose.
allowPorts = [
  { start = 22, end = 22 },
  { start = 80, end = 80 },
  { start = 443, end = 443 },
  { start = 6443, end = 6443 },
  { start = 7500, end = 7500 },
  { start = 8080, end = 8080 }
]

webServer.port = 7500
webServer.user = "USERNAME"
# ... other configurations

[auth]
token = "YOUR_SECRET_TOKEN"
```

## Step 2: Copy the Updated Configuration to the VPS

Once you have saved the changes locally, you need to upload the updated `frps.toml` file to your remote server where the `frps` service is running. You can use the `scp` command for this.

Replace `YOUR_USERNAME`, `YOUR_VPS_IP`, and the remote path with your actual values.

```bash
scp /path/to/your/local/frp/frps.toml YOUR_USERNAME@YOUR_VPS_IP:/etc/frp/frps.toml
```
*   **Note:** A common location for the configuration on the server is `/etc/frp/frps.toml`, but your path might be different.

## Step 3: Restart the `frps` Service on the VPS

After copying the file, you must restart the `frps` service for the changes to take effect. Connect to your VPS via SSH and use `systemctl` to restart the service.

```bash
ssh YOUR_USERNAME@YOUR_VPS_IP "sudo systemctl restart frps"
```

If you are already connected to the VPS, simply run:
```bash
sudo systemctl restart frps
```

## Step 4: Verify the Service Status

You can check if the service has restarted correctly and is running without errors by checking its status.

```bash
sudo systemctl status frps
```

After these steps, your `frps` server will be running with the new configuration, and your `frpc` clients will be able to connect and use the newly allowed ports.