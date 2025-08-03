# Manual SSL Certificate Generation and Usage for Kubernetes

This guide outlines the process for manually generating a wildcard SSL certificate using `certbot` with a DNS challenge and configuring it for a Kubernetes Ingress. This method is necessary for private or local domains (e.g., `.dev`) where the standard HTTP-01 challenge is not feasible.

## Prerequisites

- `certbot` client installed on your local machine.
- `kubectl` configured to access your Kubernetes cluster.
- Access to your domain's DNS management panel to add TXT records.

---
## Step 1: Install Certbot

The recommended method for installing `certbot` is using `snapd`. This ensures you have the latest version.

1.  **Install Certbot:**
    
```bash
sudo snap install --classic certbot
```

2.  **Prepare the `certbot` command (create a symbolic link):**
    
```bash
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

---
## Step 2: Generate the Wildcard Certificate

We will request a certificate for the root domain and all its subdomains (`luis122448.dev` and `*.luis122448.dev`).

1.  **Run the `certbot` command:**
    
```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges=dns \
  --server https://acme-v02.api.letsencrypt.org/directory \
  -d "luis122448.dev" \
  -d "*.luis122448.dev"
```

2.  **Follow the on-screen instructions.** `certbot` will pause and ask you to deploy a DNS TXT record. It will look something like this:

```
Please deploy a DNS TXT record under the name:
_acme-challenge.luis122448.dev.

with the following value:
<some-long-random-string>

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```

3.  **Create the TXT Record:** Go to your DNS provider's control panel and create a new TXT record with the name and value provided by `certbot`.

4.  **Verify and Continue:** Wait a few minutes for the DNS record to propagate. You can use a tool like `dig` to verify:
    
```bash
dig -t TXT _acme-challenge.luis122448.dev
```

Once you see the correct value, press `Enter` in the `certbot` terminal.

---
## Step 3: Locate Your Certificate Files

If successful, `certbot` will save your certificate files in `/etc/letsencrypt/live/luis122448.dev/`. The two files we need are:
- `fullchain.pem`: The full certificate chain.
- `privkey.pem`: The private key.

---
## Step 4: Create the Kubernetes TLS Secret

Kubernetes requires the certificate and key to be base64 encoded within a `Secret` manifest.

1.  **Encode the files:** Run these commands and copy the output.
    
```bash
# Encode the certificate
sudo cat /etc/letsencrypt/live/luis122448.dev/fullchain.pem | base64 | tr -d '\n'

# Encode the private key
sudo cat /etc/letsencrypt/live/luis122448.dev/privkey.pem | base64 | tr -d '\n'
```

2.  **Create `secret.yaml`:** Use the provided `secret.yaml` file in this directory. Paste the base64-encoded strings you just copied into the corresponding fields.

```yaml
# frp/cert-manager/manual/nginx-test-tls-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-test-tls-secret
  namespace: ingress-nginx
type: kubernetes.io/tls
data:
  tls.crt: PASTE_YOUR_BASE64_CERTIFICATE_HERE
  tls.key: PASTE_YOUR_BASE64_PRIVATE_KEY_HERE
```

---
## Step 5: Configure and Apply the Ingress

The provided `ingress.yaml` is already configured to use the secret you are creating. It references `test-luis122448-dev-tls-secret` directly and does **not** include the `cert-manager.io/cluster-issuer` annotation.

```yaml
# frp/cert-manager/manual/nginx-test-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-test-ingress-manual
  namespace: ingress-nginx
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: "test.luis122448.dev"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-service
            port:
              number: 80
  tls:
  - hosts:
    - "test.luis122448.dev"
    secretName: nginx-test-tls-secret
```

---
## Step 6: Apply Manifests to the Cluster

Once your `secret.yaml` is complete, apply both manifests.

```bash
# Apply the secret first
kubectl apply -f /srv/developer-server/frp/cert-manager/manual/nginx-test-tls-secret.yaml

# Apply the ingress
kubectl apply -f /srv/developer-server/frp/cert-manager/manual/nginx-test-ingress.yaml
```

---
## Step 7: Renewal (Important!)

These certificates expire after 90 days. Since this is a manual process, **it will not auto-renew**. You must repeat these steps to generate a new certificate and update the Kubernetes secret before the current one expires.

```