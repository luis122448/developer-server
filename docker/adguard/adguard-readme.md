# AdGuard Home

Network-wide DNS server with ad/tracker blocking. Runs with `network_mode: host`
so it can bind the DNS port (53) directly on the machine.

## Ports (host network)

| Port | Purpose                          |
| ---- | -------------------------------- |
| 53   | DNS (TCP/UDP)                    |
| 3000 | Web UI — initial setup only      |
| 80   | Web UI / dashboard after setup   |

## Setup

```bash
docker compose up -d
```

1. Open `http://<server-IP>:3000` and complete the setup wizard.
2. Choose the admin web UI port (e.g. `80`) and the DNS listen port (`53`).
3. Point your router's (or each device's) DNS to `<server-IP>`.

## Notes

- **Port 53 conflict**: if the host runs `systemd-resolved`, it already holds port 53.
  Free it first (disable `DNSStubListener` in `/etc/resolved.conf` and repoint
  `/etc/resolv.conf`) or AdGuard will fail to bind.
- Data persists in `./work` (runtime) and `./conf` (configuration).
