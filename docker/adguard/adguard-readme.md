# AdGuard Home

Network-wide DNS server with ad/tracker blocking.

## Ports

| Port | Purpose            |
| ---- | ------------------ |
| 53   | DNS (TCP/UDP)      |
| 3000 | Web UI (dashboard) |

## Setup

```bash
docker compose up -d
```

1. Open `http://<server-IP>:3000` and complete the setup wizard.
2. Keep the admin web UI on port `3000` and the DNS listen port on `53`.
3. Point your router's (or each device's) DNS to `<server-IP>`.

## Notes

- **Port 53 conflict**: if the host runs `systemd-resolved`, it already holds port 53.
  Free it first (disable `DNSStubListener` in `/etc/systemd/resolved.conf` and repoint
  `/etc/resolv.conf`) or AdGuard will fail to bind.
- **Per-client stats**: with explicit port mapping AdGuard sees the Docker gateway as the
  client for every query. To get per-device stats/filtering (or to run DHCP), switch to
  `network_mode: host` instead of the `ports:` mapping.
- Data persists in `./work` (runtime) and `./conf` (configuration).
