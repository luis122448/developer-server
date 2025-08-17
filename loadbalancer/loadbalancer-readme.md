# Installation Kubernetes in Rasberry PI and N100 Intel

This setup uses **HAProxy** for load balancing the Kubernetes API server and **Keepalived** to manage a **Virtual IP (VIP)** for high availability. The HAProxy instances will run on dedicated nodes (or nodes acting in that role), which will share the VIP.

---
## Planning Your Network

Before proceeding, it's vital to assign unique, permanent IP addresses to each of your load balancer nodes and identify the Virtual IP (VIP) that Keepalived will manage.

* **Virtual IP (VIP) for Kubernetes API / HAProxy:** `192.168.100.230`
    * This IP will **float** between your load balancer nodes. It should **NOT** be a permanent IP of any device.
* **Load Balancer Node 1 (e.g., `n100-004` - Keepalived MASTER):** Assign a unique static IP.
    * **Permanent IP Example:** `192.168.100.184`
* **Load Balancer Node 2 (e.g., `nas-001` - Keepalived BACKUP / NFS Server):** Assign a unique static IP.
    * **Permanent IP Example:** `192.168.100.171` (This node will also host your NFS server, so it needs its own stable IP).

---
## HAProxy Installation and Configuration

Edit the HAProxy configuration file located at `./loadbalancer/haproxy.cfg.j2`.

This configuration balances TCP traffic to three Kubernetes master nodes (`192.168.100.181`, `192.168.100.182`, `192.168.100.183`). The HAProxy node listens on `192.168.100.230:6443` for Kubernetes API traffic and serves a statistics page on port `8404`.

```bash
# Install HAProxy on the load balancer nodes (MASTER and BACKUP)
ansible-playbook -i ./config/inventory.ini ./loadbalancer/haproxy.yml --ask-become-pass
```

---
## Keepalived Installation and Configuration

Keepalived is responsible for managing the VIP (`192.168.100.230`) and ensuring high availability. It will assign the VIP to the `MASTER` node and float it to a `BACKUP` node if the `MASTER` fails (or `HAProxy` fails on the `MASTER`).

```bash
# Install Keepalived on the load balancer nodes (MASTER and BACKUP)
ansible-playbook -i ./config/inventory.ini ./loadbalancer/keepalived/keepalived.yml --ask-become-pass
```

---
## Managing and Validating HAProxy

Run the validation playbook to check config and service status on all load balancers:

```bash
# Validate HAProxy configuration and service status
ansible-playbook -i ./config/inventory.ini ./loadbalancer/haproxy-validate.yml --ask-become-pass
```

---
## Troubleshooting

If errors occur, connect to the server and review service output:

```bash
systemctl status haproxy.service
journalctl -xeu haproxy.service
```

---
## View Statistics Page: 

Access the HAProxy statistics page via a web browser. This page is crucial for monitoring the health of your frontends and backend servers.
Default URL (based on example config): `http://192.168.100.230:8404/stats` (replace IP with your HAProxy node's IP if different).
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
  --control-plane-endpoint="192.168.100.230:6443" \
  --upload-certs \
  # ... other necessary kubeadm flags (e.g., --pod-network-cidr, --cri-socket)
```

*Important* : Execute scripts as the `root` user.