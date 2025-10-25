# Local Docker Registry

This directory contains the configuration to run a local Docker image registry using the official `registry:2` image.

## Requirements

- Docker
- Docker Compose

## Setup and Usage

1.  **Start the Registry:**

From this directory (`docker/registry`), run the following command to start the registry container in the background:

```bash
docker-compose up -d
```

The registry will be listening on port `5000` of your host machine.

2.  **Tag an Image:**

To push an image to your local registry, you must first tag it with the format `localhost:5000/<your-image-name>`.

For example, if you have an image named `my-app:latest`:

```bash
docker tag my-app:latest localhost:5000/my-app:latest
```

3.  **Push the Image:**

Now, push the tagged image to your local registry:

```bash
docker push localhost:5000/my-app:latest
```

4.  **Pull the Image:**

From any machine with access to the host, you can pull the image:

```bash
docker pull localhost:5000/my-app:latest
```

## Important Note about HTTP

By default, Docker requires registries to use HTTPS. However, it makes an exception for `localhost`.

If you want to access this registry from **other machines** on your network, you need to configure the Docker daemon on those client machines to trust this "insecure" registry (because it uses HTTP).

To do this, edit (or create) the `/etc/docker/daemon.json` file on the client machine and add the following configuration, replacing `<registry-server-ip>` with the IP address of the machine running this registry:

```json
{
"insecure-registries" : ["<registry-server-ip>:5000"]
}
```

After saving the file, restart the Docker service on that machine (e.g., `sudo systemctl restart docker`).

## Stopping the Registry

To stop and remove the registry container, run:

```bash
docker-compose down
```

The data (images) will persist in the local `data/` volume within this directory.