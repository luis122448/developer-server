# Brave — Backup & Restore

Procedures for the `brave_brave_config` Docker volume. This volume contains
the entire Brave profile, extensions, bookmarks, history and downloads.

## Naming convention

```
brave_config_YYYYMMDD_HHMMSS.tar.gz
```

## Create a backup

The container can stay running — Brave writes its state incrementally so
a hot tar is consistent for typical use. For a fully clean snapshot stop
the container first.

```bash
# Hot backup (container running)
docker run --rm \
  -v brave_brave_config:/data:ro \
  -v /srv/developer-server/docker/brave/backups:/backup \
  alpine \
  tar czf /backup/brave_config_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

```bash
# Cold backup (container stopped)
docker compose stop brave
docker run --rm \
  -v brave_brave_config:/data:ro \
  -v /srv/developer-server/docker/brave/backups:/backup \
  alpine \
  tar czf /backup/brave_config_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
docker compose start brave
```

## Recommended backup destinations

| Destination | Path | When |
|-------------|------|------|
| NFS / external storage | `/mnt/nas/backups/brave/` | First choice when available |
| Local on the server | `/srv/developer-server/docker/brave/backups/` | Fast, no redundancy |
| Kopia repository | configured via the `kopia` stack | Encrypted, deduplicated, off-host |

The recommended long-term answer is Kopia — point a Kopia source at the
volume mount path and let it handle retention, encryption and replication.

## Restore from backup

```bash
docker compose stop brave

docker run --rm \
  -v brave_brave_config:/data \
  -v /path/to/backups:/backup:ro \
  alpine \
  sh -c "find /data -mindepth 1 -delete; \
         tar xzf /backup/brave_config_YYYYMMDD_HHMMSS.tar.gz -C /data"

docker compose start brave
```
