# Invidious in Docker

This configuration deploys [Invidious](https://invidious.io/), a private, ad-free, open-source alternative front-end to YouTube.

## Overview

This is a two-container stack:

1.  `invidious`: The main web application.
2.  `database`: A PostgreSQL database used by Invidious to store its data.

Docker Compose manages the connection between the two services.

## Getting Started

1.  **Navigate to the directory**:

```bash
cd /srv/developer-server/docker/invidious
```

2.  **Launch the service**:

```bash
docker compose up -d
```

It may take a minute or two for the Invidious container to start up and connect to the database for the first time.

## Accessing Invidious

Once the containers are running, you can access the Invidious web interface from your browser.

-   **URL**: `http://<SERVER_IP>:4502`

## Data Persistence

All data for the Invidious database is persisted on the host machine in the `postgres-data` directory, which will be automatically created in this folder.

## Service Management

-   **To stop the service**:

```bash
docker compose down
```

-   **To view logs**:

```bash
docker compose logs -f invidious
```