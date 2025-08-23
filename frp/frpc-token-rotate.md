# How to Update FRP Token After a Security Incident

If your FRP token has been compromised or accidentally exposed, you must rotate it immediately to secure your setup. This guide outlines the steps to generate a new token and update it on both the FRP server (`frps`) and the FRP client (`frpc`) running in your Kubernetes cluster.

---
## Steps to Rotate the FRP Token

### 1. Generate a New Secure Token

First, generate a new, strong, and random token. You can use a command-line tool like `openssl` to create a cryptographically secure token.

```bash
openssl rand -hex 32
```

This will generate a 32-character hexadecimal string. Copy this new token.

### 2. Update the Token on the FRP Server (frps)

Next, you need to update the configuration on your central FRP server (the machine running `frps`).

1.  **SSH into your FRP server.**
2.  **Edit the `frps.toml` (or `frps.ini`) configuration file.** Locate the `[auth]` section and replace the old token with the new one you generated.

```bash
sudo nano /etc/frp/frps.toml
```

```toml
# ... other configurations
[auth]
token = "YOUR_NEW_TOKEN"
# ... other auth settings
```

3.  **Restart the `frps` service** to apply the changes.

```bash
sudo systemctl restart frps
```

### 3. Update the Token on the FRP Client (frpc) in Kubernetes

Your `frpc` is running inside your Kubernetes cluster and its configuration is managed by a `ConfigMap`. You need to update this `ConfigMap`.

1.  **Edit the `frpc-configmap.yaml` manifest file.** Replace the placeholder `TOKEN` with your new token.

```yaml
# frpc-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: frpc-config
    namespace: ingress-nginx
data:
    frpc.toml: |
    serverAddr = "VPS_IP"
    serverPort = 7000

    [auth]
    token = "YOUR_NEW_TOKEN"

    [[proxies]]
    name = "nginx-http-luis122448-com"
    type = "http"
    localIP = "192.168.100.240"
    localPort = 80
```

2.  **Apply the updated `ConfigMap` to your cluster.**

```bash
kubectl apply -f ./frp/frpc-configmap.yaml
```

3.  **Restart the `frpc` pods** to force them to load the new configuration from the updated `ConfigMap`. Assuming your client is managed by a Deployment named `frpc-deployment`:

```bash
kubectl rollout restart deployment frpc-client -n ingress-nginx
```

If your deployment has a different name, replace `frpc-deployment` accordingly.
