# *arr suite

Prowlarr + Sonarr + Radarr + Bazarr. The classic media automation pipeline:
Prowlarr feeds shared indexers to Sonarr (TV) and Radarr (movies); Bazarr
fetches subtitles for whatever Sonarr and Radarr already manage. Sends
downloads to the `qbittorrent` stack and writes finished media into a layout
Plex/Jellyfin can pick up.

## How to start the service

```bash
docker compose up -d
```

Ports: `9696` Prowlarr, `8989` Sonarr, `7878` Radarr, `6767` Bazarr.

## Host filesystem layout (required before first start)

The compose expects this exact tree on the host. Create it once with the
correct ownership (`PUID=1000:PGID=1000`) before bringing the stack up:

```
/mnt/server/
├── arr/
│   ├── prowlarr/config/
│   ├── sonarr/config/
│   ├── radarr/config/
│   └── bazarr/config/
├── downloads/                    # qBittorrent writes here
└── video/
    ├── tv/                       # Sonarr's library root
    └── movies/                   # Radarr's library root
```

`/mnt/server` MUST be a single filesystem. Sonarr and Radarr move finished
files from `downloads/` to `video/` and rely on hardlinks for that move to
be instantaneous and disk-cheap; cross-filesystem moves degrade to full
copies and waste disk.

## Why `/mnt/server:/data` (and not separate mounts)

Sonarr, Radarr and Bazarr all mount the whole tree as `/data` instead of
binding `downloads/` and `video/` separately. This is intentional so that
the paths each app sees match the paths qBittorrent reports — without that
matching, the "atomic move" (rename, not copy) cannot happen.

## qBittorrent integration

Inside each *arr, configure the download client pointing at the
qBittorrent stack (`docker/qbittorrent/`). Use the LAN IP of the host that
runs qBittorrent and the path mapping:

| In qBittorrent | In *arr |
|----------------|---------|
| `/downloads`   | `/data/downloads` |

Both refer to the same physical directory; the mapping just tells *arr how
to translate paths the client reports.

## Data

- `/mnt/server/arr/<app>/config` — app state (settings, history, DB).
- `/mnt/server/downloads` — incoming files from qBittorrent.
- `/mnt/server/video/{tv,movies}` — managed library.

All state lives on the host filesystem, not in Docker named volumes. Back
up `arr/*/config` (small but losing it means re-importing every series and
movie); the library itself is the data that actually matters and should
be on storage you trust.

## Deployment status

Not deployed yet. Choose the node that owns the `/mnt/server` filesystem
(same host as qBittorrent) before running `docker compose up -d`.
