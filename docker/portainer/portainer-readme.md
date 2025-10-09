# How to Install and Configure Portainer

Portainer is a lightweight web UI that allows you to easily manage your Docker environments.

## Prerequisites

- Docker and Docker Compose installed on your system.

## Installation

1.  **Create a volume for Portainer data:**

The `docker-compose.yml` file included in this directory will automatically create a `portainer-data` directory in the same location to persist Portainer's data.

2.  **Deploy Portainer:**

In the `docker/portainer` directory, run the following command to start Portainer in detached mode:

```bash
docker compose up -d
```

## Configuration

1.  **Access the Web UI:**

Open your web browser and navigate to `http://<your-server-ip>:9000`.

2.  **Initial Setup:**

- The first time you access the UI, Portainer will prompt you to create an administrator user. Set a username and a secure password.

3.  **Connect to the Local Docker Environment:**

- After creating the admin user, you will be asked to connect Portainer to a Docker environment.
- Select the "Local" option to manage the Docker environment where Portainer is running.
- Click "Connect".

That's it! You can now start managing your containers, images, volumes, and networks through the Portainer interface.
