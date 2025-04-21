# Navidrome Deployment with Docker Compose

This `docker-compose.yml` file configures a container to run Navidrome, a music streaming server.

---
## Important Configuration: Permissions (`PUID` and `PGID`)

The environment variables `PUID` and `PGID` are crucial to ensure that Navidrome has the correct permissions to access your music library and save its configuration.

* **`PUID`**: Represents the User ID (UID) of the user on your host server. Navidrome will use this ID to interact with the files within the mounted volumes.
* **`PGID`**: Represents the Group ID (GID) of the group on your host server. Similar to `PUID`, it defines the group with which Navidrome will operate.

---
**How to find your UID and GID?**

Open a terminal on your server and run the following command:

```bash
id
```

The output will show information about your user, including your `uid` and `gid`. Replace the default values (`1000`) in the `docker-compose.yml` file with the values you obtain from this command.

Example:

If running `id` gives you `uid=1001(myuser) gid=1001(mygroup)`, your configuration in `docker-compose.yml` should be:

```yml
environment:
      - PUID=1001
      - PGID=1001
      # ... other variables ...
```

---
## Starting the Container

To start the Navidrome container in the background, run the following command in the same location where you saved the `docker-compose.yml` file:

```bash
sudo docker compose up -d
```

This command will download the Navidrome image (if you don't have it already) and create and run the container according to the defined configuration. You can access Navidrome in your browser at `http://localhost:8003` (or your server's IP address if you are not accessing it locally).