# FRP (Fast Reverse Proxy) Configuration for Exposing Local Kubernetes Services to the Internet

This `README.md` documents the step-by-step configuration of FRP to expose services from a local Kubernetes cluster to the Internet via a VPS (Remote Server).

**Architecture:**
* **FRP Server (frps):** Installed on a VPS with a public IP.
* **FRP Client (frpc):** Running as a Pod within a local Kubernetes cluster.
* **Service to Expose:** An Nginx Ingress in the local Kubernetes cluster, exposing HTTP/HTTPS services.

**FRP Version:** `v0.62.1`

**Official FRP Documentation:** [https://github.com/fatedier/frp](https://github.com/fatedier/frp)

---
## FRP Server (`frps`) Configuration on the VPS

This section details the installation and configuration of the FRP server component on your VPS.

### Binary Download and Preparation

The binary path will be `/usr/local/bin/frps`.

- Connect to your VPS via SSH:
 
```bash
ssh your_user@your_vps_public_ip
```

- Create necessary directories

```bash
sudo mkdir -p /etc/frp
sudo mkdir -p /usr/local/bin
```

- Download the `frps` binary for Linux AMD64 (common VPS architecture):

We will use version `0.62.1`.

```bash
cd /tmp
wget [https://github.com/fatedier/frp/releases/download/v0.62.1/frp_0.62.1_linux_amd64.tar.gz](https://github.com/fatedier/frp/releases/download/v0.62.1/frp_0.62.1_linux_amd64.tar.gz)
tar -zxvf frp_0.62.1_linux_amd64.tar.gz
```

- Copy the binary to the desired path and give it execute permissions:

```bash
sudo cp frp_0.62.1_linux_amd64/frps /usr/local/bin/frps
sudo chmod +x /usr/local/bin/frps
```

- Verify the version of the copied binary:

```bash
/usr/local/bin/frps --version
# Should display: 0.62.1
```

- Clean up temporary files:

```bash
rm -rf /tmp/frp_0.62.1_linux_amd64 /tmp/frp_0.62.1_linux_amd64.tar.gz
```

- `frps.toml` Configuration File

The configuration file will be located at `/etc/frp/frps.toml`.

- Create or edit the `frps.toml` file:

```bash
sudo nano /etc/frp/frps.toml
```

- Paste the following content (ensure your token and dashboard password are set):

```toml
bindPort = 7000
vhostHTTPPort = 80
vhostHTTPSPort = 443

# Dashboard Configuration
webServer.port = 7500
webServer.user = "admin"
webServer.password = "PASSWORD"
webServer.addr = "0.0.0.0"

[auth]
token = "TOKEN"
```

Save and exit the editor (`Ctrl+X`, `Y`, `Enter`).

### Creating, Starting and Enabling the `systemd` Service for `frps`

This will allow `frps` to run in the background and start automatically with the VPS.

- Create the `systemd` service file:

```bash
sudo nano /etc/systemd/system/frps.service
```

- Paste the following content:

```ini
[Unit]
Description = FRP Server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/bin/frps -c /etc/frp/frps.toml
Restart = on-failure

[Install]
WantedBy = multi-user.target
```

Save and exit the editor.

- Reload the `systemd` daemon and enable the service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable frps
```

- Start the `frps` service:

```bash
sudo systemctl start frps
```

- Verify the service status and its logs:

```bash
sudo systemctl status frps
# Should show "Active: active (running)"
sudo journalctl -u frps.service -f
# Look for success messages in the logs
```

### Firewall Configuration (UFW) on the VPS

**!This step is CRITICAL for connections to reach your `frps`!**

- Activate UFW and allow necessary ports:**

```bash
sudo ufw allow 7000/tcp  # Connection port for frpc clients
sudo ufw allow 80/tcp   # For HTTP traffic to be forwarded to Ingress
sudo ufw allow 443/tcp  # For HTTPS traffic to be forwarded to Ingress
sudo ufw allow 7500/tcp # If you decided to keep the web dashboard
```

- Verify the firewall status:


```bash
sudo ufw status verbose
# Ensure "Status: active" and "ALLOW" rules are present.
```

---
## FRP Client (`frpc`) Configuration in Kubernetes

This section details the `frpc` client configuration for your Kubernetes cluster. Manifests are grouped in the `./frc` directory.

- Create or edit the `./frc/configmap.yaml` file:

```yaml
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
    token = "TOKEN"

    [[proxies]]
    name = "nginx-ingress-http"
    type = "http"
    localIP = "192.168.100.240"
    localPort = 80
    customDomains = ["test.luis122448.com"]

    [[proxies]]
    name = "nginx-ingress-https"
    type = "https"
    localIP = "192.168.100.240"
    localPort = 443
    customDomains = ["test.luis122448.com"]
```

**Important:** Copy and paste the exact content of your `frpc.toml` inside the `frpc.toml: |` section and ensure it's properly indented (usually with 2 additional spaces).

- Create or edit the `./frc/deployment.yaml` file:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frpc-client
  namespace: ingress-nginx
  labels:
    app: frpc-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frpc-client
  template:
    metadata:
      labels:
        app: frpc-client
    spec:
      containers:
      - name: frpc
        image: fatedier/frpc:v0.62.1
        command: ["/usr/bin/frpc"]
        args: ["-c", "/etc/frp/frpc.toml"]
        volumeMounts:
        - name: frpc-config-volume
          mountPath: /etc/frp
      volumes:
      - name: frpc-config-volume
        configMap:
          name: frpc-config
          items:
          - key: frpc.toml
            path: frpc.toml
```

### Applying Manifests in Kubernetes

- Apply the `ConfigMap`:

```bash
kubectl apply -f ./frc/configmap.yaml
```

- Delete any existing `frpc-client` Deployment to ensure a clean installation:

```bash
kubectl delete deployment frpc-client -n ingress-nginx # If it exists, it will delete it
```

- Apply the `Deployment`:

```bash
kubectl apply -f ./frc/deployment.yaml
```

- Verify the status of the `frpc-client` Pod:

```bash
kubectl get pods -n ingress-nginx -l app=frpc-client
# Wait for the status to be "Running"
```

- Check the logs of the `frpc-client` Pod to confirm the connection:

```bash
kubectl logs -f <frpc_client_pod_name> -n ingress-nginx
# You should see "login to server success" and proxies established.
```

---
## DNS Configuration

Ensure your domain points to your VPS's public IP.

**In your DNS provider**, create an `A` record for `test.luis122448.com` pointing to `VPS_IP`.

**Verify DNS propagation:**, You can use tools like `dig test.luis122448.com` or online services like [https://www.whatsmydns.net/](https://www.whatsmydns.net/).

---
## Final Access Test

Once all components are functional and DNS has propagated.

- How to Remove the `/etc/hosts` Entry. Look for the line you added for `test.luis122448.com`. It will likely look something like this:

```bash
LOCAL_IP   test.luis122448.com
```

Or it might include `www.test.luis122448.com` as well. Delete that entire line (or lines).

- From anywhere with Internet access**, try to access your service:

```bash
curl [http://test.luis122448.com](http://test.luis122448.com)
```

Or open the URL in your web browser.

---
This provides a comprehensive documentation for your `FRP` setup! You can now proceed with implementing `HTTPS` using `cert-manager`.