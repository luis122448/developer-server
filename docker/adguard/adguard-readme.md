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
2. **⚠️ On the "Admin Web Interface" step, set the port to `3000` — NOT the default `80`.**
   This compose only publishes ports `3000` and `53`. If you leave the admin UI on `80`
   (the wizard default), AdGuard moves the dashboard to a port that is **not published**
   and you lock yourself out (the wizard finishes, then `:3000` stops responding).
3. Keep the DNS listen port on `53`.
4. Point your router's (or each device's) DNS to `<server-IP>`.

## Troubleshooting

### Locked out of the dashboard (`:3000` stops responding after setup)

Cause: the admin UI was left on port `80` during the wizard, which this compose does not
publish. Fix it by forcing the admin UI back to `3000`:

```bash
CONF=conf/AdGuardHome.yaml
sudo sed -i 's|address: 0.0.0.0:80|address: 0.0.0.0:3000|' "$CONF"
docker restart adguard
```

DNS on `53` keeps working the whole time — only the dashboard is affected.

## Notes

- **Port 53 conflict**: if the host runs `systemd-resolved` (or Pi-hole/dnsmasq), it already
  holds port 53. Free it first or AdGuard fails to bind.
- **Per-client stats**: with explicit port mapping AdGuard sees the Docker gateway as the
  client for every query. For per-device stats/filtering (or DHCP), use `network_mode: host`
  instead of the `ports:` mapping.
- Data persists in `./work` (runtime) and `./conf` (configuration, incl. `AdGuardHome.yaml`).
