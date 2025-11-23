# External Access Setup for Kubernetes Cluster

This document explains how to securely expose your private Kubernetes cluster's API Server to the outside world using an FRP (Fast Reverse Proxy) tunnel.

## 1. Identify the Cluster Load Balancer

For an external `kubectl` client to communicate with the cluster, it needs to connect to the API Server. In a high-availability (HA) setup, the API Server is exposed through an internal Load Balancer.

- **Load Balancer IP**: You must identify the IP address of your Load Balancer (usually HAProxy). This is the IP to which `frpc` will redirect traffic.
- **API Server Port**: The standard port for the Kubernetes API Server on the Load Balancer is `6443`.

## 2. Configure the FRP Client (`frpc`)

Add a new section in your `frpc.toml` configuration file to redirect a public port from your `frps` server to the cluster's API Server.

Edit your `frpc.toml` file and add the following:

```toml
[[proxies]]
name = "k8s-api"
type = "tcp"
localIP = "LOAD_BALANCER_IP" # <-- REPLACE with your Load Balancer's IP
localPort = 6443
remotePort = 6443 # <-- YOU CAN CHANGE THIS if port 6443 is not available on your FRPS server
```

**Important Notes:**

- `localIP`: This is the IP of the server where the Load Balancer that points to the Kubernetes masters is running.
- `remotePort`: This is the port that will be opened on your public server (where `frps` is running). Developers will connect to this port. Make sure it is not already in use.

## 3. Restart the `frpc` Service

After saving the changes, restart the `frpc` service for the new proxy configuration to take effect.

```bash
sudo systemctl restart frpc
```

With this, your cluster's API Server is now accessible from the outside via `YOUR_FRPS_DOMAIN:REMOTE_PORT`. The next step is to create credentials for the developer.