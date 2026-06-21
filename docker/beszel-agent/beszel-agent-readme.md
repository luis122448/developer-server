# Beszel Agent

Lightweight metrics collector. Reads system stats from `/proc` and `/sys`
and container stats from the Docker socket, then registers itself with the
central Beszel Hub.

Deploy one instance per host you want to monitor, including the node where
the Hub runs.

## How to start the service

```bash
cp .env.example .env
# In the Hub UI click "Add System" and copy these three values into .env:
#   HUB_PUBLIC_KEY   (ssh-ed25519 ... line, quoted)
#   HUB_TOKEN        (per-agent token shown in the dialog)
#   HUB_URL          (e.g. http://192.168.100.142:9000)
docker compose up -d
```

The agent listens on port `9003` and uses `network_mode: host` so the Hub
sees the real host IP — required for the SSH-based pairing.

## Verifying

```bash
docker logs beszel-agent --tail 20
```

A healthy agent logs `agent listening` and stops printing
`Failed to load public keys`. If you still see that error, the value of
`HUB_PUBLIC_KEY` is wrong — it must be the full `ssh-ed25519 ...` line, not
the `TOKEN`. Quote the value in `.env` because it contains spaces.

## Data

- `beszel_agent_data` — local state (registration cache). Recreatable; the
  Hub remains the source of truth.
