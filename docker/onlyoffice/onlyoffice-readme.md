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
To ensure OnlyOffice works correctly, it must be accessible from both the **Nextcloud server** and your **web browser**.

### External Access (Browser)
The URL must be public or accessible from your local network via an Nginx Proxy/Ingress.
*   **Example URL:** `https://onlyoffice.bbg.pe/`
*   In Nextcloud "Document Editing Service address", enter your public HTTPS URL.

### Internal Access (Optimization)
In Nextcloud "Advanced server settings", you can set the internal Docker address to speed up server-to-server communication:
*   **Internal address:** `http://onlyoffice-documentserver/`

## Proxy Configuration
This setup is designed to work behind an **Nginx Proxy** (e.g., in a Kubernetes cluster) pointing to the server IP on port **8008**.

## Persistence
All data is stored in Docker volumes, ensuring no information is lost when restarting the container.
