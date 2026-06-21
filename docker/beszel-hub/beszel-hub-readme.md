# Beszel Hub

Central web UI and metrics database for Beszel. Receives system and container
stats from agents running on each monitored node and serves the dashboard.

This is the SERVER side of Beszel. Agents on each node connect outbound to
this Hub via SSH. Deploy one Hub per homelab, not one per node.

## How to start the service

```bash
cp .env.example .env
docker compose up -d
```

The service will be available at port `9000`.

## First-time setup

1. Open `http://<HUB-HOST-IP>:9000` and create the admin account.
2. Settings → SSH keys → copy the Hub's public key. This is the value that
   every agent will need in its `HUB_PUBLIC_KEY` variable.
3. For each monitored node, deploy `docker/beszel-agent/` with that public key,
   then return here and click "Add System" — name it, point at the agent's
   IP and port, accept the fingerprint.

## Data

- `beszel_data` — SQLite database with users, systems, metrics history,
  and the Hub's SSH keypair. Losing this volume means re-pairing every
  agent and losing historical metrics.

## Backup

The volume is small (typically <100 MB) and easy to snapshot. Worth adding
as a Kopia source on the host where the Hub runs.
