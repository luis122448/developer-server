# HTTPS Configuration with cert-manager on Kubernetes

This `README.md` outlines the steps to enable HTTPS for services exposed via Nginx Ingress on your local Kubernetes cluster, using `cert-manager` to automate certificate management from Let's Encrypt.

**Goal:** Secure `https://test.luis122448.com` with a valid TLS certificate.

**Key Components:**
* **Kubernetes Cluster:** Running locally (e.g., Raspberry Pi nodes).
* **FRP (Fast Reverse Proxy):** Already configured to tunnel traffic from your VPS (public IP) to your local Kubernetes Ingress Controller on ports 80 and 443.
* **Nginx Ingress Controller:** Installed and operational in the `ingress-nginx` namespace.
* **`cert-manager`:** Kubernetes operator for automated certificate management.
* **Domain:** `test.luis122448.com`
* **cert-manager Version:** `v1.18.1`

**Prerequisites:**
1.  Your FRP setup (server and client) is fully operational as documented previously.
2.  Your domain `test.luis122448.com` is correctly pointing via an `A` record to your VPS's public IP.
3.  Your VPS firewall (UFW) allows traffic on ports `80`, `443`, and `7000` (for FRP).

---
## Install `cert-manager` in Your Kubernetes Cluster

`cert-manager` will handle the entire lifecycle of your TLS certificates.

- Add the Jetstack Helm repository and update:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

- Create the dedicated `cert-manager` namespace:

```bash
kubectl create namespace cert-manager
```

- Install `cert-manager` Custom Resource Definitions (CRDs):

It's crucial to install the CRDs *before* the main Helm chart. Ensure the version matches the Helm chart version you plan to install.

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.1/cert-manager.crds.yaml
```

- Install the `cert-manager` Helm chart:

```bash
helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.18.1 \
    --set installCRDs=false # CRDs are already installed manually
```

- Verify `cert-manager` Pods are running:

Allow a minute or two for pods to start.

```bash
kubectl get pods -n cert-manager
# Expected output: cert-manager-xxx, cert-manager-cainjector-xxx, cert-manager-webhook-xxx in Running state.
```

---
## Configure a `ClusterIssuer` for Let's Encrypt

A `ClusterIssuer` is a cluster-scoped resource that tells `cert-manager` how to obtain certificates from an ACME (Automated Certificate Management Environment) provider like Let's Encrypt. We'll use the `HTTP-01` challenge type, which is compatible with your FRP setup.

- Create a `cluster-issuer.yaml` file:

```bash
nano cluster-issuer.yaml
```

- Paste the following content:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod # This name will be referenced in your Ingress
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your.email@example.com # Let's Encrypt uses this for important notifications.
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

- Apply the `ClusterIssuer`:

```bash
kubectl apply -f cluster-issuer.yaml
```

- Verify the `ClusterIssuer` status:

```bash
kubectl get clusterissuer letsencrypt-prod -w
# Look for "READY: True" and a status message indicating it's ready to issue certificates.
```

---
## 3. Deploy Your Nginx Test Application (`nginx-test-app.yml`)

Ensure your application is deployed in the same namespace where your Ingress will reside (`ingress-nginx`).

- Create or edit the `nginx-test-app.yml` file:**

```bash
nano nginx-test-app.yml
```

- Paste the following content:

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test-deployment
  namespace: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
  namespace: ingress-nginx
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

- Apply version:

```bash
kubectl apply -f nginx-test-app.yml
```

- Verify application Pods and Service Endpoints:

```bash
kubectl get pods -n ingress-nginx -l app=nginx-test
# Ensure Pods are Running and Ready
kubectl get svc -n ingress-nginx nginx-test-service
kubectl describe svc -n ingress-nginx nginx-test-service
# Ensure the "Endpoints" section lists your Pod IPs.
```

---
## Configure Your Ingress (`ingress-principal.yaml`) for HTTPS

Finally, you will modify your existing Ingress to leverage `cert-manager` for TLS.

- Create or edit your `ingress-principal.yaml` file:**

```bash
nano ingress-principal.yaml
```

Update the file with `cert-manager` annotations and the `tls` section:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-principal
  namespace: ingress-nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: "test.luis122448.com"
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
    - test.luis122448.com
    secretName: test-luis122448-com-tls
```

- Apply the updated Ingress:

```bash
kubectl apply -f ingress-principal.yaml
```

---
## Verify Certificate Issuance and HTTPS Access

`cert-manager` will now process the Ingress and attempt to obtain the certificate.

- Monitor the `Certificate` resource:

```bash
kubectl get certificate -n ingress-nginx
# Look for "test-luis122448-com-tls". It should eventually show "READY: True".
# This might take a few minutes as cert-manager communicates with Let's Encrypt.
```

If `READY` stays `False`, use `kubectl describe certificate test-luis122448-com-tls -n ingress-nginx` to check the `Events` section for errors. You can also check cert-manager pod logs: `kubectl logs -f -n cert-manager -l app.kubernetes.io/name=cert-manager`.

Verify the TLS `Secret` is created:
Once the `Certificate` is `READY: True`.

```bash
kubectl get secret test-luis122448-com-tls -n ingress-nginx
# Should show a Secret of type "kubernetes.io/tls".
```

- Test `HTTPS` Access from a web browser or `curl`:

```bash
curl -v [https://test.luis122448.com](https://test.luis122448.com)
# Verify the SSL handshake and the content of your Nginx page.
```

Also, test the `HTTP` to `HTTPS` redirection:

```bash
curl -v [http://test.luis122448.com](http://test.luis122448.com)
# This should show an HTTP 308 Permanent Redirect to the HTTPS URL.
```

You have now successfully configured `HTTPS` with automated certificate management for your Kubernetes service accessible via `FRP`!