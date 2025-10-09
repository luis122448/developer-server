# Brave Browser in Docker (Kasm)

This configuration deploys a standalone instance of the Brave browser using a Kasm image, making it accessible via a web browser. It's a lightweight alternative to a full remote desktop like Webtop.

This setup is configured to persist user data, load the password from an environment file, and stream audio.

## 1. Prerequisite: Create .env file

Before launching, you must create a `.env` file in this directory (`/srv/developer-server/docker/brave/`). This file will hold the password for the VNC connection.

Create the file with the following content:

```
PASSWORD=your_secure_password_here
```

Replace `your_secure_password_here` with a strong password of your choice.

## 2. Getting Started

1.  **Navigate to the directory**:

```bash
cd /srv/developer-server/docker/brave
```

2.  **Launch the service**:

```bash
docker compose up -d
```

## 3. Accessing Brave

Once the container is running, you can access the Brave session from your local web browser.

-   **URL**: `https://<SERVER_IP>:8005`

> **Note**: You must use `https`. Your browser will show a security warning because the service uses a self-signed certificate. You need to accept the risk and proceed to the page.

-   **Username**: `kasm_user`
-   **Password**: The password you set in the `.env` file.

## 4. Enabling Audio

Audio streaming is enabled in the configuration, but it might be muted by default in the web interface.

1.  Once in the session, move your mouse to the **left edge of the screen** to reveal a fly-out tab.
2.  Click the tab to open the **Kasm Control Panel**.
3.  Find the **Audio** settings section.
4.  Make sure audio is **enabled/unmuted** and adjust the volume as needed.

## 5. Data Persistence

This service is configured to persist Brave's user data (bookmarks, extensions, history, etc.). All data is stored on the host machine in the `/mnt/server/brave` directory, as defined in the `docker-compose.yml` file.

## 6. Service Management

-   **To stop the service**:

```bash
docker compose down
```

-   **To view logs**:

```bash
docker compose logs -f
```

-   **To apply configuration changes**:

```bash
docker compose up -d --force-recreate
```