# FRP (Fast Reverse Proxy) Configuration for Exposing Local Kubernetes Services to the Internet

This `frp-readme.md` documents the step-by-step configuration of FRP to expose services from a local Kubernetes cluster to the Internet via a VPS (Remote Server).

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
wget https://github.com/fatedier/frp/releases/download/v0.62.1/frp_0.62.1_linux_amd64.tar.gz
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

**How to Generate a Secure Token**: For the `TOKEN` value, you should use a long, random, and secret string.

```bash
openssl rand -hex 32
```
5cd9d83d6b8ca39670b2f21e54992c8bc298f2218dd1951327a58a307ea318a1
- Create or edit the `frps.toml` file:

```bash
sudo mkdir -p /etc/frp
sudo nano /etc/frp/frps.toml
```

- Paste the following content (ensure your token and dashboard password are set):

```toml
bindPort = 7000

# Dashboard Configuration
webServer.port = 7500
webServer.user = "USERNAME"
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

### External Port Validation (Optional but Recommended)

To be certain that the ports are reachable from the internet, you can test them from your **local machine** (or any other external server). This helps diagnose issues beyond the server's firewall, such as network restrictions from your hosting provider.

**Using `nmap` (Powerful Port Scanner)**

`nmap` is a versatile tool for network discovery.

```bash
# Replace YOUR_VPS_IP with your server's public IP address
nmap -p 7000,80,443,7500 YOUR_VPS_IP
```

**Expected Output (for open ports):** You should see the state as `OPEN` for each port that is correctly configured.
    
```
PORT     STATE    SERVICE
80/tcp   open     http
443/tcp  open     https
7000/tcp open     ...
7500/tcp open     ...
```

**`filtered` or `closed` State:** If a port shows as `filtered`, it means a firewall or network device is blocking the connection. If it's `closed`, it means the server is responding, but no application is listening on that port.

**Using `nc` (Netcat - A simpler alternative)**

Netcat is a simpler tool that can also test TCP connections.

```bash
# The -z flag scans for listening daemons, -v provides verbose output.
nc -zv YOUR_VPS_IP 80
nc -zv YOUR_VPS_IP 443
nc -zv YOUR_VPS_IP 7000
nc -zv YOUR_VPS_IP 7500
```

**Expected Output (for open ports):** You should see a "succeeded" message.

```
Connection to YOUR_VPS_IP 80 port [tcp/http] succeeded!
```

**Failed Connection:** If the connection fails, the command will hang and eventually time out, or return an error immediately.

---
## FRP Client (`frpc`) Configuration in Kubernetes

This section details the `frpc` client configuration for your Kubernetes cluster. Manifests are grouped in the `./frc` directory.

- Create or edit the `./frc/frpc-configmap.yaml` file:

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
    type = "tcp"
    localIP = "192.168.100.240"
    localPort = 80
    remotePort = 80

    [[proxies]]
    name = "nginx-ingress-https"
    type = "tcp"
    localIP = "192.168.100.240"
    localPort = 443
    remotePort = 443
```

**Important:** Copy and paste the exact content of your `frpc.toml` inside the `frpc.toml: |` section and ensure it's properly indented (usually with 2 additional spaces).

- Create or edit the `./frc/frpc-deployment.yaml` file:

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
kubectl apply -f ./frp/frpc-configmap.yaml
```

- Delete any existing `frpc-client` Deployment to ensure a clean installation:

```bash
kubectl delete deployment frpc-client -n ingress-nginx # If it exists, it will delete it
```

- Apply the `Deployment`:

```bash
kubectl apply -f ./frp/frpc-deployment.yaml
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

- Performs a rolling restart of the deployment to apply configuration changes

```bash
kubectl rollout restart deployment frpc-client -n ingress-nginx
```

---
## DNS Configuration

Ensure your domain points to your VPS's public IP.

**In your DNS provider**, create an `A` record for `test.luis122448.com` pointing to `VPS_IP`.

**Verify DNS propagation:**, You can use tools like `dig test.luis122448.com` or online services like [https://www.whatsmydns.net/](https://www.whatsmydns.net/).

---
## Final Access Test

Once all components are functional and DNS has propagated.

- Create a Namespace for test applications:

```bash
kubectl create namespace nginx-test
```

- Create the Nginx Test Application `nginx-test-app.yml`

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test-deployment
  namespace: nginx-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
  namespace: nginx-test
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f nginx-test-app.yml
```

- Complete and Apply the Ingress Manifest `ingress-principal.yml`

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-principal
  namespace: nginx-test
spec:
  ingressClassName: nginx
  rules:
  - host: "test.luis122448.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-service
            port:
              number: 80
```

- Apply the Ingress manifest:

```bash
kubectl apply -f ingress-principal.yml
```

- From anywhere with Internet access**, try to access your service:

```bash
# Or open the URL in your web browser.
curl http://test.luis122448.com
```

**Important** After testing delete the test namespace and resources to clean up:

```bash
kubectl delete namespace nginx-test
```

---
## HTTPS Configuration: Two Approaches

Once HTTP is working, you can secure your services with HTTPS. There are two primary architectures for handling encrypted traffic with `frp` and Kubernetes. The best choice depends on your needs, especially regarding wildcard domains.

### Approach 1: Server-Side TLS Termination (Original Method)

In this model, the `frps` server on the VPS is responsible for terminating the TLS connection. It holds the SSL certificate and decrypts the traffic before forwarding it to the `frpc` client.

*   **How it Works:** `frpc` uses `type = "https"` to inform `frps` to handle TLS. `frps` listens on `vhostHTTPSPort` and uses its own certificate (often obtained automatically via Let's Encrypt for specific domains) to serve traffic.

*   **Pros:**
    *   Conceptually simple for basic setups.
    *   No need to manage certificates inside the Kubernetes cluster if `frps` handles it all.

*   **Cons:**
    *   **Does NOT support wildcard domains** without a complex DNS-01 challenge setup on the `frps` server.
    *   Requires you to **explicitly list every single subdomain** in your `frpc.toml` file.
    *   The `frps` server becomes a bottleneck for TLS processing and a critical point for certificate management.

#### Server (`frps.toml`) Configuration

This approach requires `vhostHTTPSPort` to be set on the server.

```toml
# /etc/frp/frps.toml on VPS
bindPort = 7000

# Listens for HTTPS traffic and terminates TLS
vhostHTTPPort = 80
vhostHTTPSPort = 443

[auth]
token = "YOUR_SECRET_TOKEN"
```

#### Client (`frpc.toml`) Configuration

You must list every subdomain. Wildcards (`*`) will not work.

```toml
# frpc.toml inside the ConfigMap
serverAddr = "VPS_IP"
serverPort = 7000

[auth]
token = "YOUR_SECRET_TOKEN"

[[proxies]]
name = "nginx-https-proxy"
type = "https"
localIP = "YOUR_INGRESS_CONTROLLER_IP" # e.g., 192.168.100.240
localPort = 443
customDomains = ["dota-shuffle.your-domain.com", "www.your-domain.com", "another.your-domain.com"]
```

---
### Approach 2: TLS Passthrough (Recommended for Wildcard & Dynamic Subdomains)

In this model, the `frps` server acts as a transparent tunnel, forwarding the encrypted HTTPS traffic directly to the Ingress Controller inside your Kubernetes cluster. Your Ingress Controller (using `cert-manager`) is responsible for terminating TLS.

*   **How it Works:** `frpc` uses `type = "tcp"` for the HTTPS port. This tells `frps` to simply forward the raw TCP packets without trying to decrypt them. The Ingress Controller receives the encrypted traffic and uses its certificate (which can be a wildcard certificate) to handle the request.

*   **Pros:**
    *   **Fully supports wildcard domains (`*.your-domain.com`) automatically.**
    *   **Single Source of Truth:** All certificate management is handled inside Kubernetes by `cert-manager`, which is cleaner and more robust.
    *   **Set it and forget it:** Add a new subdomain in your DNS and Ingress manifest, and it works instantly. No need to edit `frpc.toml` or `frps.toml` again.

*   **Cons:**
    *   Requires a coordinated configuration change on both the client (`frpc`) and server (`frps`).

#### Server (`frps.toml`) Configuration

This approach requires you to **remove** the `vhost_..._port` lines from your server configuration to avoid port conflicts.

```toml
# /etc/frp/frps.toml on VPS
bindPort = 7000

# IMPORTANT: Ensure vhostHTTPPort and vhostHTTPSPort are REMOVED or commented out.
# The TCP proxy from frpc will instruct frps to listen on the required ports directly.

[auth]
token = "YOUR_SECRET_TOKEN"
```

#### Client (`frpc.toml`) Configuration

This configuration is simpler and does not require listing every domain. It creates a transparent tunnel for all HTTP and HTTPS traffic.

```toml
# frpc.toml inside the ConfigMap
serverAddr = "VPS_IP"
serverPort = 7000

[auth]
token = "YOUR_SECRET_TOKEN"

# Proxy for HTTPS traffic (Passthrough)
[[proxies]]
name = "nginx-https-passthrough"
type = "tcp"
localIP = "YOUR_INGRESS_CONTROLLER_IP" # e.g., 192.168.100.240
localPort = 443
remotePort = 443

# Proxy for HTTP traffic (Passthrough, for redirects)
[[proxies]]
name = "nginx-http-passthrough"
type = "tcp"
localIP = "YOUR_INGRESS_CONTROLLER_IP" # e.g., 192.168.100.240
localPort = 80
remotePort = 80
```