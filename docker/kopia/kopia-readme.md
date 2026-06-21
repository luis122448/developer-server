# Kopia

Encrypted, deduplicated, snapshot-based backup tool. Runs in server mode with
a web UI for managing the repository and snapshots.

This stack is configured to back up the `vaultwarden_data` volume on the host
where it runs. Vaultwarden must already exist on the same node — Kopia mounts
its data volume as an external read-only source.

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
4. Add `/data/vaultwarden` as a snapshot source.
5. Configure a policy: retention (e.g. 7 daily, 4 weekly, 12 monthly), zstd
   compression, and an hourly or daily schedule.

## SQLite consistency

Vaultwarden stores its data in a SQLite database (`db.sqlite3`). A file-level
snapshot of a live SQLite file CAN be inconsistent if it is captured mid-write.
For a homelab single-user vault the practical risk is low, but the correct
fix is to register a Kopia "before snapshot" action that runs the SQLite
online backup command into a sibling file, and snapshot that file:

```
sqlite3 /data/vaultwarden/db.sqlite3 ".backup /data/vaultwarden/db.sqlite3.bak"
```

Configure this in the UI under the source's Actions panel once the source is added.

## Restoring data

- From the UI: navigate to the snapshot → "Restore Files" → pick destination.
- From the CLI inside the container:

  ```bash
  docker exec -it kopia kopia snapshot list
  docker exec -it kopia kopia mount <snapshot-id> /mnt/restore
  ```

## Off-site replication

The current setup writes the repository locally on the same host as Vaultwarden,
which protects against accidental deletion and data corruption but NOT against
a full host failure. To replicate the repository to another node (e.g. `.141`
or `.109`), use `kopia repository sync-to` against an SFTP/rclone destination.
This is a follow-up step, not included in the current compose.

## Data

- `kopia_config` — repository connection info and policies.
- `kopia_cache` — local cache of metadata and frequently-accessed blocks.
- `kopia_logs` — operational logs.
- `vaultwarden_data` — mounted read-only from the existing Vaultwarden stack.
- `KOPIA_REPO_PATH` on the host — the actual backup repository. Must live on
  a different disk than the source data, otherwise a disk failure takes both.
