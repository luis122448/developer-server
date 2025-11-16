# Build and Push Custom code-server Image

This directory contains the `Dockerfile` to build a custom `code-server` image with pre-installed tools (Node.js, Python, etc.).

## Prerequisites

- Docker installed and running on a machine.
- Logged into your Harbor registry (`harbor.bbg.pe`). If not, run:
  ```bash
  docker login harbor.bbg.pe
  ```

## Step 1: Build the Image

From this directory (`docker/code-server/`), run the `docker build` command. This will create your image and tag it for your Harbor registry.

We assume your Harbor project is named `library`. If it's different, change `library` to your project's name in the command below.

```bash
docker build -t harbor.bbg.pe/library/code-server:custom .
```

## Step 2: Push the Image to Harbor

Push the newly built image to your private registry.

```bash
docker push harbor.bbg.pe/library/code-server:custom
```

---

Once you have completed these steps, the image `harbor.bbg.pe/library/code-server:custom` will be ready, and we can proceed with the Kubernetes deployment in the `k8s/code` directory.
