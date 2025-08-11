# Let's Encrypt Certificate Generation with Certbot (DNS Challenge)

Specific guide referenced: [Generate Lets Encrypt Certificate](https://ongkhaiwei.medium.com/generate-lets-encrypt-certificate-with-dns-challenge-and-namecheap-e5999a040708)

---
## Step 1: Install Let’s Encrypt Certbot 

```bash
sudo apt install certbot
```

---
## Step 2: Generate new certificate using Certbot

The command to generate the cert is relatively simple. You can do for single domain, for multiple domains then just needs to append -d DOMAIN. In this case I used *.DOMAIN so that the certificate can be used for subdomain as well. The wizard will ask for a few simple information.

```bash
sudo certbot certonly --manual --preferred-challenges dns -d "bbg.pe" -d "*.bbg.pe"
```

**Note**: Replace `bbg.pe` with your actual domain name.

---
## Step 3: Setting DNX TXT ACME Challenge in Namecheap

Once Y is entered in the previous step, Certbot will revert with ACME challenge token to be configured in DNS provider to allow verification. Copy the token and insert as TXT record in DNS console of Namecheap.

```bash
- - - - - - - - - - - 
Register in namecheap 
- - - - - - - - - - -
Please deploy a DNS TXT record under the name:
_acme-challenge [_acme-challenge.bbg.pe]
with the following value:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---
## Step 4: Verify TXT record 

Please set TTL to 1 minute to allow Top-level DNS servers to pick up this new subdomain — _acme-challenge.DOMAIN. You can verify this DNS TXT record using nslookup before proceed with verification.

```bash
nslookup -type=TXT _acme-challenge.bbg.pe
```

---
## Step 5: Verify the domain challenge

Press Enter and Certbot will continue with the verification process.

```bash
- - - - - -
Successfully 
- - - - - -
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/bbg.pe/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/bbg.pe/privkey.pem
This certificate expires on 2024-10-21.
```

---
## Step 6: Retrieve the certificate

You will hit permission error when trying to retrieve the file. This is due to folder permission of /etc/letsencrypt/liveis set to root. Therefore we can set permission to allow other users to read via sudo chmod +x /etc/letsencrypt/live

```bash
sudo chmod +x /etc/letsencrypt/live
```

---
## Extra: Copy the certificate to the VPS Server

Connect to the remote server (VPS) and create the destination directory

```bash
sudo mkdir -p /etc/letsencrypt/live/bbg.pe
```

**Note**: Replace `bbg.pe` with your domain name if different.

Change ownership of the directory (Optional), This might be necessary if your user doesn't have write permissions to copy files via scp.

```bash
sudo chown -R $USER:$USER /etc/letsencrypt/live/
```

Copy the certificate files using scp

```bash
sudo scp /etc/letsencrypt/live/bbg.pe/* $USER@$VPS_SERVER:/etc/letsencrypt/live/bbg.pe/
```

**Note** Replace `$USER` with your username on the VPS and `$VPS_SERVER` with the IP address or hostname of your VPS.