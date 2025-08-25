# How to Expose a New Service via FRP

This guide explains the process for exposing a new application running in Kubernetes to the internet using the existing `frp` (Fast Reverse Proxy) setup.

---
## Prerequisite: Verify Port on VPS

Before configuring anything in Kubernetes, you **must** ensure the port you want to use is open on the VPS firewall and any cloud network security groups.

Use `nc` (netcat) from your local machine to test the connectivity. Replace `<VPS_IP>` with your server's IP and `<PORT>` with the public port you want to use.

```bash
nc -zv <VPS_IP> <PORT>
```

**Expected Output (Success):**
```
Connection to <VPS_IP> port <PORT> [tcp/*] succeeded!
```

**Expected Output (Failure):**
```
nc: connect to <VPS_IP> port <PORT> (tcp) failed: Connection timed out
```
or
```
nc: connect to <VPS_IP> port <PORT> (tcp) failed: Connection refused
```

If the test fails, you must fix the firewall rules on your VPS or cloud provider before proceeding.

---
## New Proxy to `frpc`

You need to tell the `frpc` client about your new service by adding a proxy configuration to its `ConfigMap`.

**Edit the file:** `frp/frpc-configmap.yaml`

Add a new `[[proxies]]` block to the `frpc.toml` section inside the `ConfigMap`.

### Proxy Configuration Template

```toml
[[proxies]]
name = "app-name-passthrough"
type = "tcp"
localIP = "your-service-name.namespace.svc.cluster.local"
localPort = 8080
remotePort = 8080
```

-   `name`: A unique name for your proxy (e.g., `my-app-proxy`).
-   `type`: Use `tcp` for most applications.
-   `localIP`: The internal Kubernetes DNS name of your service. The format is `<service-name>.<namespace>.svc.cluster.local`.
-   `localPort`: The port your Kubernetes `Service` is listening on.
-   `remotePort`: The public port on your VPS that will route to your service. **This is the port you tested in Step 1.**

### Apply and Refresh the Configuration

After saving the changes to `frpc-configmap.yaml`, you must apply them to the cluster and restart the `frpc` pods for the changes to take effect.

**1. Apply the ConfigMap:**
```bash
kubectl apply -f frp/frpc-configmap.yaml
```

**2. Restart the `frpc` deployment:**
```bash
kubectl rollout restart deployment frpc-client -n ingress-nginx
```

The pods will restart, load the new configuration, and start proxying traffic for your new service.
