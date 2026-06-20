# Homepage — homelab dashboard

A single landing page that indexes every service across the homelab servers, grouped by
host. Built with [gethomepage](https://gethomepage.dev) — configured entirely via the YAML
files in `config/` (no code), so the whole dashboard is versioned in git.

## Servers mapped

| Server     | IP              | Apps shown                                            |
| ---------- | --------------- | ----------------------------------------------------- |
| orange-001 | 192.168.100.141 | Portainer, AdGuard, Uptime Kuma, Speedtest, KMS       |
| orange-002 | 192.168.100.142 | Brave, Uptime Kuma                                    |
| dev-001    | 192.168.100.161 | code-server ×2, Nextcloud, OnlyOffice, Trilium, …     |
| dev-005    | 192.168.100.165 | Code Server, Brave, Registry, pgAdmin                 |

## Run

```bash
docker compose up -d
```

Then open `http://<host-where-it-runs>:9002`.

- Port `9002` (host) → `3000` (container).
- `HOMEPAGE_ALLOWED_HOSTS` (in the compose) lists the host:port combos you may access it
  from. It already covers the four candidate servers on `:9002`; add more if needed.

## Config files (`config/`)

| File             | Purpose                                  |
| ---------------- | ---------------------------------------- |
| `settings.yaml`  | Title, theme, per-group layout           |
| `services.yaml`  | Services grouped by server (href cards)  |
| `widgets.yaml`   | Top info widgets (clock, host resources) |
| `bookmarks.yaml` | Quick links                              |

## Optional: live widgets (status pulled from each app's API)

The cards are plain links by default. Many apps support a live widget (e.g. AdGuard shows
queries blocked, Portainer shows running containers). These need credentials, so keep them
out of git via env vars (`.env` is gitignored):

1. Add to a `.env` next to the compose, e.g.:

   ```bash
   HOMEPAGE_VAR_ADGUARD_USER=admin
   HOMEPAGE_VAR_ADGUARD_PASS=yourpassword
   ```

2. Reference them in `services.yaml` under the service:

   ```yaml
   - AdGuard Home:
       href: http://192.168.100.141:3000
       widget:
         type: adguard
         url: http://192.168.100.141:3000
         username: "{{HOMEPAGE_VAR_ADGUARD_USER}}"
         password: "{{HOMEPAGE_VAR_ADGUARD_PASS}}"
   ```

Widgets exist for Portainer, AdGuard, qBittorrent, Uptime Kuma, Speedtest Tracker and more.
See <https://gethomepage.dev/widgets/>.
