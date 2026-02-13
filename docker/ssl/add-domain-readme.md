# Adding a New Domain (brave.bbg.pe)

This guide explains how to secure and serve the new `brave` container on `brave.bbg.pe` without disrupting existing services.

## Prerequisites

*   The `brave` container must be running (Port 8005).
*   The DNS for `brave.bbg.pe` must point to this server's IP (`192.168.100.142` locally, or your public IP if accessing externally).

## Step 1: Create the Setup Configuration

First, we create a basic Nginx configuration that listens on port 80. This allows Certbot to verify the domain and generate the SSL certificate.

1.  Create the file:

```bash
sudo nano /etc/nginx/sites-available/brave.bbg.pe.conf
```

2.  Paste the following content:

```nginx
server {
    listen 80;
    server_name brave.bbg.pe;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
```

3.  Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/brave.bbg.pe.conf /etc/nginx/sites-enabled/
```

4.  Test and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Step 2: Generate the SSL Certificate

Run Certbot to obtain the certificate. This will automatically verify your domain and authenticate it.

```bash
sudo certbot --nginx -d brave.bbg.pe
```

*   **Note**: If asked to redirect HTTP traffic to HTTPS, you can select "2" (Redirect), though our config already handles this. Certbot might modify the file to add its own redirect; this is fine.

## Step 3: Configure the Proxy (Final Configuration)

Now that we have the certificate, we need to tell Nginx to forward traffic to the Brave container running on port **8005**.

1.  Edit the configuration file again:
```bash
sudo nano /etc/nginx/sites-available/brave.bbg.pe.conf
```

2.  Update the `server` block listening on port 443 (SSL). It should look like this (ensure you keep the SSL paths Certbot added):

```nginx
server {
    listen 443 ssl;
    server_name brave.bbg.pe;

    # --- Certbot will have added these lines automatically ---
    # ssl_certificate ...
    # ssl_certificate_key ...
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    # -------------------------------------------------------

    location / {
        # Point to the Brave container port (8005)
        # Use https because Kasm/Brave images use self-signed HTTPS by default
        proxy_pass https://localhost:8005;

        # Necessary for Kasm/Brave to work correctly behind a proxy
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket Support (Crucial for interaction)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;

        # Disable SSL verification for slightly faster upstream connection
        # (since we are trusting localhost)
        proxy_ssl_verify off;
    }
}

server {
    listen 80;
    server_name brave.bbg.pe;
    # ... (keep existing redirect) ...
}
```

3.  Test and reload again:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Step 4: Verify Auto-Renewal

Certbot automatically installs a systemd timer (or cron job) to handle renewals. You generally don't need to do anything.

To verify that auto-renewal is set up correctly, run a dry-run test:

```bash
sudo certbot renew --dry-run
```

If this command completes without errors, your certificates (including the new one for `brave.bbg.pe`) will renew automatically before they expire.
