# Installation Kubernetes in Rasberry PI and N100 Intel

Install HAProxy on a dedicated node. This node will act as the stable endpoint for your Kubernetes API servers.

---
## HAProxy Installation and Configuration

Edit the HAProxy configuration file located at `./loadbalancer/haproxy.cfg.j2`.

This configuration balances TCP traffic to three Kubernetes master nodes (`192.168.100.181`, `192.168.100.182`, `192.168.100.183`). The HAProxy node listens on `192.168.100.171:6443` for Kubernetes API traffic and serves a statistics page on port `8404`.

```bash
ansible-playbook -i ./config/inventory.ini ./loadbalancer/ha_proxy.yml --ask-become-pass
```

---
## Managing and Validating HAProxy

Validate Configuration

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check Service Status (Debug Command)

```bash
systemctl status haproxy.service
```

View Logs (Debug Command)

```bash
journalctl -xeu haproxy.service
```

---
## View Statistics Page: 

Access the HAProxy statistics page via a web browser. This page is crucial for monitoring the health of your frontends and backend servers.
Default URL (based on example config): `http://192.168.100.171:8404/stats` (replace IP with your HAProxy node's IP if different).
Key information on the stats page:

- Status of kubernetes-frontend (should be `OPEN`).
- Status of kubernetes-backend and individual master nodes (`master1`, `master2`, `master3`). Healthy servers will show as `UP` (green). Servers failing health checks will be marked as `DOWN` (red), with a reason provided (e.g., L4CON for connection refused, L4TOUT for timeout).

## Firewall Configuration ( Optional, includes in Ansible Script )

Ensure the firewall on the HAProxy node allows incoming traffic on the ports HAProxy uses:

- Port `6443/tcp` (for the Kubernetes API traffic).
- Port `8404/tcp` (for the HAProxy statistics page, if enabled).

---
## Kubernetes Integration

When initializing your Kubernetes control plane using `kubeadm`, specify the HAProxy node's IP address and the frontend port as the control plane endpoint:

```bash
kubeadm init \
  --control-plane-endpoint="192.168.100.171:6443" \
  --upload-certs \
  # ... other necessary kubeadm flags (e.g., --pod-network-cidr, --cri-socket)
```

*Important* : Execute scripts as the `root` user.