# Plex Media Server Deployment (Docker Compose)

This file configures a Plex Media Server.

---
## Important Configuration: Permissions (`PUID` and `PGID`)

Ensure proper access to your configuration and media. Replace the default values in `environment` with your server's UID and GID (obtained with the `id` command).

---
## Starting the Container

Execute:

```bash
docker compose up -d
```

Access the web interface at `http://<your_server_ip>:8004/web`.
