# Vaultwarden

Self-hosted Bitwarden-compatible password manager. Lightweight Rust implementation
of the Bitwarden server API, fully compatible with official Bitwarden clients
(browser extensions, mobile apps, desktop apps, CLI).

## How to start the service

```bash
cp .env.example .env
# Generate an admin token hash and paste it into .env:
docker run --rm -it vaultwarden/server /vaultwarden hash
# Edit .env and fill DOMAIN and ADMIN_TOKEN
docker compose up -d
```

The service will be available at port `8011`.

## First-time setup

1. Open `http://<YOUR-SERVER-IP>:8011` and create your account.
2. Once your account exists, edit `.env` and set `SIGNUPS_ALLOWED=false`.
3. Restart the stack: `docker compose up -d`.
4. The admin panel lives at `http://<YOUR-SERVER-IP>:8011/admin`
   (only reachable if `ADMIN_TOKEN` is set).

## Clients

- Browser extensions: install official Bitwarden extension, then on login screen
  click the gear icon and set "Server URL" to your DOMAIN.
- Mobile: Bitwarden app → Settings → Self-hosted environment → Server URL.
- Desktop: same flow as mobile.
- CLI: `bw config server http://<YOUR-SERVER-IP>:8011`

## Import from KeePass

1. KeePassXC → File → Export → CSV.
2. Bitwarden web vault → Tools → Import Data → Format: KeePass 2 (.csv).
3. Verify everything imported, then securely delete the CSV.

## Data

All credentials, attachments, configuration and the SQLite database live in
the `vaultwarden_data` volume. This volume is the ONLY thing you need to back
up — losing it means losing every password stored here.

## Backup notes

- Stop the container or use `sqlite3 .backup` before snapshotting the volume
  to avoid backing up a live database file.
- The data is already encrypted at the application level, but the volume
  itself is not — treat it as sensitive when shipping it offsite.
