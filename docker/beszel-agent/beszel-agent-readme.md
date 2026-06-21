# Beszel Agent

Lightweight metrics collector. Reads system stats from `/proc` and `/sys`,
container stats and recent logs from the Docker socket, and serves them to
the Beszel Hub over SSH on port 9003.

Deploy one instance per host you want to monitor — including the node where
the Hub itself runs.

## How to start the service

```bash
cp .env.example .env
# Paste HUB_PUBLIC_KEY from the Hub UI (Settings → SSH keys).
docker compose up -d
```

The agent listens on port `9003`. The Hub must be able to reach this port
on the agent's host IP — no port forwarding needed if both live on the same
LAN.

## Registering the agent with the Hub

1. Confirm the agent is healthy: `docker compose logs -f beszel-agent` should
   show "agent listening".
2. In the Hub UI, click "Add System".
3. Name it after the host (`orange-002`, `dev-001`, etc.).
4. Host: the agent's LAN IP. Port: `9003`.
5. Accept the SSH fingerprint shown by the Hub.

## Data

This stack has no persistent volume. Configuration is fully driven by the
environment variable and the Docker socket mount. Recreate the container
freely.
