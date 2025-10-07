# Nginx and Let's Encrypt Setup on Ubuntu Server

This guide provides instructions on how to install Nginx and secure it with free SSL certificates from Let's Encrypt for multiple subdomains on Ubuntu Server.

## 1. Nginx Installation

Follow these steps to install Nginx on your Ubuntu Server.

### Step 1: Update System Packages

First, update your system's package index.

```bash
sudo apt-get update -y
```

### Step 2: Install Nginx

Install the Nginx web server.

```bash
sudo apt-get install nginx -y
```

### Step 3: Enable and Start Nginx

Enable the Nginx service to start on boot and start it immediately.

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

### Step 4: Verify Nginx Status

Check if Nginx is running correctly.

```bash
sudo systemctl status nginx
```
You should see an "active (running)" status.

### Step 5: Configure Firewall

If a firewall is enabled, allow HTTP and HTTPS traffic.

```bash
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### Step 6: Test Connection

After configuring Nginx, it's crucial to test your connection to ensure everything is working as expected. You can do this in two primary ways:

```bash
curl $SERVER_IP
```

You should see the "Welcome to nginx!" message within the output.

## 2. Securing Nginx with Let's Encrypt (HTTP-01 Challenge)

This section explains how to secure Nginx with free SSL certificates for the subdomains `example.domain.com`, `dashboard.domain.com`, and `storage.domain.com`.

### Step 1: Install Certbot

On Ubuntu Server, Certbot can be installed from the default repositories.

1.  Install Certbot and the Nginx Plugin

```bash
sudo apt install python3-certbot-nginx -y
```

### Step 2: Configure Nginx for the Domains

Before running Certbot, you need an Nginx configuration file for your domains. Certbot will look for a `server_name` directive that matches the domains you're requesting a certificate for.

1.  Create a new configuration file for your domains.
    
```bash
sudo nano /etc/nginx/sites-available/domain.com.conf
```

2.  Add the following server block to the file. This configures Nginx to listen on port 80 for all three subdomains.

```nginx
server {
    listen 80;
    server_name example.domain.com;

    root /var/www/html;
    index index.html index.htm;

    location /.well-known/acme-challenge/ {
        allow all;
        root /var/www/html;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

3. Create a symbolic link to the `sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/domain.com.conf /etc/nginx/sites-enabled/
```

4.  Create the webroot directory if it doesn't exist.
    
```bash
sudo mkdir -p /var/www/html
echo "Welcome to my website!" | sudo tee /var/www/html/index.html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

5.  Test and reload the Nginx configuration.

```bash
sudo nginx -t
sudo systemctl reload nginx
```

6. Verify that Nginx is serving the default page by navigating to `http://example.domain.com` in your web browser.

### Step 3: Obtain the SSL Certificate

Run Certbot using the `--nginx` plugin. Provide all the domain names using the `-d` flag.

```bash
sudo certbot --nginx -d example.domain.com
```

Certbot will handle the HTTP-01 challenge, obtain the certificates, and automatically update your `/etc/nginx/sites-available/domain.com.conf` file to configure SSL. When prompted, choose the option to redirect HTTP traffic to HTTPS.

### Step 4: Verify Final Nginx Configuration

After Certbot runs, your configuration file should be automatically updated to look similar to this:

1. Updated Nginx configuration file:

```bash
sudo rm /etc/nginx/sites-available/domain.com.conf
sudo nano /etc/nginx/sites-available/domain.com.conf
```

```nginx
server {
    listen 443 ssl http2;
    server_name example.domain.com;

    # SSL certificate paths
    ssl_certificate /etc/letsencrypt/live/example.domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.domain.com/privkey.pem;

    # Recommended SSL settings
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # A default root directory for the domains
    root /var/www/html;
    index index.html;
}

server {
    listen 80;
    server_name example.domain.com;

    # Redirect all HTTP traffic to HTTPS
    return 301 https://$host$request_uri;
}
```

2. Create a symbolic link to the `sites-enabled` directory.

```bash
sudo rm /etc/nginx/sites-enabled/domain.com.conf

sudo ln -s /etc/nginx/sites-available/domain.com.conf /etc/nginx/sites-enabled/
```

3. Realod Nginx to apply the changes.

```bash
sudo systemctl reload nginx
```

*Note: Certbot will name the certificate directory after the first domain name provided (`example.domain.com`), but the certificate itself will be valid for all listed domains.*

### Step 5: Automate Certificate Renewal
The Certbot package automatically creates a systemd timer to renew your certificates before they expire. You can test the renewal process with a dry run:

```bash
sudo certbot renew --dry-run
```

If the dry run is successful, your certificates for all domains will be renewed automatically.
