# Speedtest Tracker

Internet speed monitoring with historical data (LinuxServer image).

## Port

| Port | Purpose |
| ---- | ------- |
| 8002 | Web UI  |

Access: `http://<server-IP>:8002`

## Setup

1. Set `APP_KEY` in a `.env` file next to the compose:

   ```bash
   echo "APP_KEY=base64:$(openssl rand -base64 32)" > .env
   ```

2. Start it:

   ```bash
   docker compose up -d
   ```

## Configuration

- **Schedule:** a speedtest every 4 hours (`SPEEDTEST_SCHEDULE=0 */4 * * *`).
- **Database:** SQLite, stored in the `speedtest-tracker-data` Docker volume.
- **Timezone:** `America/Lima`.

## Default login

- **Email:** `admin@example.com`
- **Password:** `password`

Change these right after the first login.

## Public exposure

The public-facing redirection (Ingress / service endpoints) lives in
`/srv/kubernetes-server`. This repo only holds the container definition.
