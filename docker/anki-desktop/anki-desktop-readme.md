# Anki Desktop (web)

The full Anki desktop application running in a container via KasmVNC, reachable
from a browser. This is the study client — open it, review cards, manage decks.
It syncs its collection against the self-hosted `anki-sync-server`, so changes
made here also reach AnkiDroid and any native desktop client.

## How to start the service

```bash
cp .env.example .env
# Confirm ANKI_SYNC_SERVER points at the sync-server (http://<IP>:8004/).
docker compose up -d
```

The web UI is at `http://<YOUR-SERVER-IP>:8006`.

## Connecting to the sync server

`ANKI_SYNC_SERVER` is passed in at startup, but Anki still needs you to sign in
once from inside the app:

1. Open the web UI and let Anki finish loading.
2. Tools → Preferences → Syncing → sign in with the sync-server credentials
   (the `SYNC_USER` / `SYNC_PASSWORD` from the anki-sync-server stack).
3. First sync: choose the direction deliberately. If the collection lives on
   the sync-server already, pull (Download). If it lives here, push (Upload).

## Version pinning (two layers)

The compose tag (`:25.09`) pins the CONTAINER (KasmVNC + base), not the Anki
app. This image installs Anki via pip at runtime through its launcher, so the
Anki version lives in the `/config` volume, chosen once from the launcher
(option 2 → "Choose a version"), and persists across restarts.

On ARM64 the latest Anki fails: its PyQt6 wheel (pyqt6-qt6 6.9.x) only targets
glibc 2.39, while this container ships glibc 2.36. Pick an Anki release on
PyQt6 6.6.x or older — `24.06.3` is known to work. Pressing Enter for "Latest"
will break the install on this architecture.

## Performance note

This runs a Qt desktop over KasmVNC. On ARM single-board hardware the UI can
feel sluggish compared to a native client. `shm_size: 1gb` and
`seccomp=unconfined` are mandatory — without them Qt WebEngine crashes.

## Security note

The web UI has no authentication by default — anyone who can reach port 8006
gets your collection. Keep it LAN-only (do not expose it), and put it behind
an authenticating reverse proxy before any external access.

## Data

- `anki_desktop_config` — the desktop's own `/config` (local collection,
  launcher, settings). This is the client's working copy; the source of truth
  is the sync-server. Distinct from the sync-server's `anki_data` volume.
