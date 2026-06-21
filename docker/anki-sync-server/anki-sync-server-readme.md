# Anki Sync Server

Self-hosted Anki sync endpoint. Replaces AnkiWeb so flashcards sync between
desktop and mobile clients without leaving the LAN.

Built from the official Anki source and published multi-arch (amd64, arm64,
arm/v7), so it runs natively on the Orange Pi nodes and tracks the current
Anki sync protocol.

## How to start the service

```bash
cp .env.example .env
# Fill SYNC_USER and SYNC_PASSWORD with the credentials Anki clients will use.
docker compose up -d
```

The service will be available at port `8004`.

## Client configuration

### Anki desktop (>=2.1.57)

1. Preferences → Network → Self-hosted sync server.
2. Set the sync URL to `http://<YOUR-SERVER-IP>:8004/` (note the trailing slash).
3. Sign in with `SYNC_USER` / `SYNC_PASSWORD`.

### AnkiDroid

1. Settings → Advanced → Custom sync server.
2. Sync URL: `http://<YOUR-SERVER-IP>:8004/`.
3. Media sync URL: same value with `/msync/` appended.
4. Sign in from the main screen with the same credentials.

## First sync from an existing collection

The first sync MUST be initiated from the client that holds the canonical
collection — usually desktop. Choosing "Upload to AnkiWeb" on the first sync
pushes the local collection to this server. Choosing "Download from AnkiWeb"
on a fresh device pulls it down. Reversing this once on the wrong device
overwrites the good collection with the empty one.

## Data

- `anki_data` — all collections and media for every user defined via SYNC_USER*.
  This is the only volume that matters; back it up.

## Notes

The image rebuilds daily against the latest Anki release, so the desktop and
AnkiDroid clients should stay compatible. If a sync ever fails after a client
update, pull a fresh image (`docker compose pull && docker compose up -d`).
