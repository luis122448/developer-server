# Kopia

Encrypted, deduplicated, snapshot-based backup tool. Runs in server mode with
a web UI for managing repositories, policies and snapshots across the homelab.

## How to start the service

```bash
cp .env.example .env
# Fill all required variables, in particular:
#   - KOPIA_REPOSITORY_PASSWORD  (store in the password manager FIRST)
#   - KOPIA_SERVER_PASSWORD
#   - KOPIA_REPO_PATH            (must exist on the host)
mkdir -p "$(grep ^KOPIA_REPO_PATH .env | cut -d= -f2)"
docker compose up -d
```

The web UI is at `http://<YOUR-SERVER-IP>:51515`.

## First-time setup

1. Open the UI, log in with `KOPIA_SERVER_USERNAME` / `KOPIA_SERVER_PASSWORD`.
2. Create a new repository pointing at `/repository` (filesystem provider).
3. When prompted for the repository password, paste `KOPIA_REPOSITORY_PASSWORD`.
4. Add `/data/developer-server` as a snapshot source.
5. Configure a policy: retention (e.g. 7 daily, 4 weekly, 12 monthly), compression
   (zstd-fastest for mixed content, none for already-compressed media), and a schedule.

## Why these mount paths

- `/data/developer-server` is mounted **read-only**. Kopia must never be able
  to modify the data it is supposed to protect.
- `/repository` is the backup destination. It MUST live on a different physical
  disk than the source data — otherwise a disk failure takes both with it.
- `kopia_config`, `kopia_cache`, `kopia_logs` are internal state. They can be
  regenerated, but losing the config volume means re-adding sources and policies
  by hand.

## Restoring data

- From the UI: navigate to the snapshot → "Restore Files" → pick destination.
- From the CLI inside the container:

  ```bash
  docker exec -it kopia kopia snapshot list
  docker exec -it kopia kopia mount <snapshot-id> /mnt/restore
  ```

  The `mount` subcommand exposes a snapshot as a read-only filesystem,
  which is the fastest way to recover a single file.

## Database-backed services

File-level snapshots of a live database (PostgreSQL, MariaDB, SQLite) can be
inconsistent. For those services, run a `pg_dump` / `mariadb-dump` / `.backup`
into a dump directory BEFORE Kopia snapshots that directory. This is configured
per-source via Kopia's "Actions" (before/after snapshot hooks).

## Data

- `kopia_config` — repository connection info and policies.
- `kopia_cache` — local cache of metadata and frequently-accessed blocks.
- `kopia_logs` — operational logs.
- The actual backup data lives at `KOPIA_REPO_PATH` on the host, NOT in a
  Docker volume. That is intentional: the repository needs to survive
  rebuilding the Kopia container.
