# OnlyOffice Document Server

This container runs the OnlyOffice Document Editing Server.

## How to start the service
```bash
docker compose up -d
```

## How to generate a secure Secret Key
You can generate a strong random token for your `ONLYOFFICE_JWT_SECRET` using one of the following Linux commands:

```bash
# Option 1: Using openssl (Recommended)
openssl rand -hex 32

# Option 2: Using /dev/urandom
head -c 32 /dev/urandom | base64
```
Copy the output and paste it into your `.env` file.

## Integration with Nextcloud
1. Access your Nextcloud instance (port 8002).
2. Go to **Apps** and install "ONLYOFFICE".
3. In **Administration settings** -> **ONLYOFFICE**:
   - Document Editing Service address: `http://onlyoffice-documentserver/` (Internal Docker network)
   - Secret Key: Use the value defined in `ONLYOFFICE_JWT_SECRET` within your `.env` file.

## Persistence
All data is stored in Docker volumes, ensuring no information is lost when restarting the container.
