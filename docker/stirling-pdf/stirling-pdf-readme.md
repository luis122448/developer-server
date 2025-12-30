# Stirling-PDF

Stirling-PDF is a powerful, locally hosted web-based PDF manipulation tool using Docker that allows you to perform various operations on PDF files, such as splitting, merging, converting, reorganizing, adding images, rotating, compressing, and more.

## Prerequisites

- Docker
- Docker Compose

## Installation

1. Navigate to the directory:

```bash
cd /srv/developer-server/docker/stirling-pdf
```

2. Start the container:
   
```bash
docker compose up -d
```

## Access

Once running, you can access Stirling-PDF at:
`http://<your-server-ip>:8007`

## Configuration

The `docker-compose.yml` file maps the container's port `8080` to the host's port `8007`.

### Volumes
- `/mnt/server/stirling-pdf/trainingData`: For custom Tesseract OCR data.
- `/mnt/server/stirling-pdf/extraConfigs`: For extra configuration files.
- `/mnt/server/stirling-pdf/logs`: For application logs.

## Features

- **Full Web Interface**: Easy to use UI for all PDF operations.
- **Merge/Split/Rotate/Move**: Organize your PDFs.
- **Convert**: PDF to Image, Image to PDF, etc.
- **Security**: Add/Remove passwords.
- **OCR**: Optical Character Recognition support.
- **Dark Mode**: Supports theme customization.
