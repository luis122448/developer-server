# VPN Port Forwarding with Ansible

A simple Ansible-based solution to automate port forwarding rules on a VPS via iptables, mapping public ports to internal VPN client services.

---
## Prerequisites

- Ansible 2.10+ installed on your control machine
- SSH access to the VPS (or run locally on the VPS with `connection: local`)
- iptables available on the target host
- Inventory configured with your VPN clients and the VPS

---
## Usage

### Apply port forwarding rules

```bash
ansible-playbook -i ./config/inventory.ini ./portforwarding/forward-ports.yml
```

This will:
- Enable IPv4 forwarding
- Create idempotent DNAT rules (with comments) for each device and port

### List all NAT PREROUTING rules

```bash
sudo iptables -t nat -L PREROUTING -n --line-numbers
```

### Remove only the DNAT rules created by this playbook (rollback)

```bash
ansible-playbook -i ./config/inventory.ini ./portforwarding/rollback-forward-ports.yml
```

### Reset all PREROUTING rules (use with caution)

> **Warning:** This will flush _all_ NAT PREROUTING rules, including Docker, Kubernetes, etc.

```bash
sudo iptables -t nat -F PREROUTING
```

---
## Customization

- **`inventory.ini`**: Define your `[vpn_clients]` and `[vps]` hosts with `ansible_vpn_host`, `ansible_host`, etc.
- **`devices.yml`**: Specify each device's `vpn_ip`, `public_base_port`, and either `internal_ports` list or `start_internal_port` and `end_internal_port`.
- **Task adjustments**: The `tasks/forward_ports_per_device.yml` uses the `ansible.builtin.iptables` module to ensure idempotency and tagging via `comment`.

Feel free to extend or modify the port ranges per device, add UDP support, or integrate into larger roles as needed. Enjoy!

