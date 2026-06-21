# Uptime Kuma

Self-hosted uptime monitoring with status pages and notifications.

This repo hosts ONLY the Docker stack. The HA reverse proxy, ingress
manifests and public status page branding (`status.bbg.pe`, `uptime.bbg.pe`,
`status1.bbg.pe`, `status2.bbg.pe`) live in `/srv/kubernetes-server` under
`apps/external/uptime-kuma/`.

## How to start the service

```bash
cp .env.example .env
docker compose up -d
```

The service will be available at port `3001`.

## First-time setup

1. Open `http://<YOUR-SERVER-IP>:3001` and create the admin account.
2. Add monitors: type `HTTP(s)` → paste the URL → save. Suggested defaults:
   - Heartbeat interval: 60s
   - Retries: 3
   - Accepted status codes: 200-399.

## Active-active deployment

In this homelab Uptime Kuma is deployed on `orange-001` (`192.168.100.141`)
AND `orange-002` (`192.168.100.142`) as independent instances. Each instance
keeps its own SQLite database and is exposed publicly through the HA Ingress
defined in the cluster repo. Configure the same monitors on both instances
to keep parity.

## Data

- `uptime-kuma-data` — SQLite database, monitors, settings, notification
  channels. This is the only volume; back it up.
