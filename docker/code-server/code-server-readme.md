# How to Set Up and Use code-server

`code-server` allows you to run VS Code on a remote server and access it through your browser.

## Prerequisites

- Docker and Docker Compose installed.

## Setup

1.  **Set Your Password:**

- Open the `docker-compose.yml` file in this directory.
- Find the `PASSWORD` and `SUDO_PASSWORD` environment variables and change `your_password` to a strong, unique password.

2.  **Directory Structure:**

- This setup will create two directories locally within `docker/code-server`:
    - `config`: Stores `code-server` settings, extensions, and user configuration.
    - `projects`: This is your main workspace. Place the code you want to work on in this directory.

3.  **Launch `code-server`:**

- Run the following command from within the `docker/code-server` directory:

```bash
docker compose up -d
```

## Accessing Your IDE

1.  **Open Your Browser:**

- Navigate to `http://<your-server-ip>:8004`.

2.  **Log In:**

- You will be prompted for a password. Use the one you set in the `docker-compose.yml` file.

You are now running a full instance of VS Code in your browser. You can open a terminal, install extensions, and edit files just like you would on your desktop.

---

## ⚠️ Important Security Notice

By default, this setup exposes `code-server` directly to the network on port `8080`. This service provides shell access to the server, so it is a **critical security risk** if not properly secured.

It is **highly recommended** that you do not expose it directly to the internet. Instead, use one of the following methods for secure access:

- **Firewall:** Use `ufw` or another firewall to restrict access to the port to only your trusted IP address.
- **SSH Tunnel:** Access it via `localhost` by creating an SSH tunnel (as discussed previously). This is a very secure method.
- **Reverse Proxy with HTTPS:** Place `code-server` behind a reverse proxy like Nginx Proxy Manager to enable SSL/TLS and add another layer of authentication.
