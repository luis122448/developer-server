# Feishin

Modern, Spotify-like **web client** for music servers. It is a *client only* — it does not
host music. It connects to the existing **Navidrome** server (`docker/navidrome/`) over its
Navidrome/Subsonic API, giving a richer UI than Navidrome's built-in one.

## Port

| Port | Purpose |
| ---- | ------- |
| 9180 | Web UI  |

Access: `http://<server-IP>:9180`

## Run

```bash
docker compose up -d
```

No secrets in the compose: Feishin stores the server connection **per browser**, set on
first launch (below).

## Connect it to Navidrome

On first load, Feishin asks for a server:

1. **Server type**: `Navidrome` (uses Navidrome's native API; richer than generic Subsonic).
2. **URL**: `http://192.168.100.161:8003`  (the Navidrome on dev-001)
3. **Username / Password**: your Navidrome credentials.
4. Save → your whole library shows up with the new UI.

## Notes

- **Same library, better client**: Navidrome stays the source of truth (scans, metadata,
  playlists). Feishin is just a nicer front end pointing at the same API.
- **Per-browser config**: each browser/device configures its own connection. There is no
  server-side state to persist, so no volume is needed.
- **HTTPS / CORS**: on plain LAN HTTP this works directly. If you later serve Feishin over a
  domain/HTTPS, make sure Navidrome is reachable over a compatible scheme to avoid
  mixed-content/CORS blocks.
- **Other clients**: since Navidrome speaks Subsonic, native apps also work great
  (Symfonium on Android, play:Sub on iOS, Supersonic/Tempo on desktop).
