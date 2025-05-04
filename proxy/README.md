# Nginx Reverse Proxy Configuration Steps

Specific guide referenced: [Nginx Reverse Proxy](https://www.swhosting.com/es/comunidad/manual/como-crear-un-proxy-inverso-con-nginx)

---
## Step 1: Check if the configured domain points to the server's IP

User `dig` or `nslookup` to verify DNS resolution before proceeding.

```bash
dig bbg.pe
```

**Note**: Replace `bbg.pe` with your actual domain name.

---
## Step 2: Install Nginx

This command updates the package list and installs Nginx.

```bash
sudo apt update
sudo apt install nginx
```

---
## Step 3: Review the reverse proxy configuration file

Ensure the 'proxy_pass' directive points to your backend application's address and port.

``` bash
cat ./proxy/bbg.pe.conf
```

Relocate the configuration file

``` bash
sudo cp ./proxy/bbg.pe.conf /etc/nginx/sites-available/bbg.pe.conf
```

Create a symbolic link from `sites-available` to `sites-enable`

```bash
sudo ln -s /etc/nginx/sites-available/bbg.pe.conf /etc/nginx/sites-enabled/
```

---
## Step 4: Verify the certificate validity

Check the details and expiration date of your SSL certificate.

```bash
sudo openssl x509 -in /etc/letsencrypt/live/bbg.pe/fullchain.pem -text -noout
```

Relocate options-ssl-nginx

```bash
sudo cp ./proxy/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf
```

Generate ssl_dhparam

```bash
sudo openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
```

---
## Step 5: Restart Nginx

Use `reload` instead of `restart` for zero-downtime reloads if safe.

```bash
sudo systemctl restart nginx
```

---
## Step 6: Check configuration status

Test the Nginx configuration syntax for errors before restarting/reloading.

```bash
    sudo nginx -t
```

Use curl to test if the reverse proxy is working and responding.

```bash
     curl -I http://bbg.pe
```

**Note**: The `-I` flag fetches only the headers.