# Adding New Applications to an Existing Kubernetes Cluster (CI/CD Integration)

This guide outlines the standardized process for integrating new applications into a Kubernetes cluster that already has core infrastructure set up, including FRP tunneling, Nginx Ingress Controller, and Cert-Manager for automated HTTPS.

**Assumptions:**
* Your core cluster infrastructure is fully operational:
  * FRP Server (`frps`) on VPS and FRP Client (`frpc`) in Kubernetes are running.
  * Nginx Ingress Controller is installed and running in the `ingress-nginx` namespace.
  * Cert-Manager is installed and configured (e.g., `letsencrypt-prod ClusterIssuer`).
  * Your domain(s) for new applications will have `A` records pointing to your VPS Public IP.

---
## Process for Deploying a New Application

Follow these steps for each new application you wish to deploy and expose via Ingress.

### Prepare Your Application Manifests

Each application should have its own set of Kubernetes manifests, ideally within its own repository or a dedicated directory.

* **`deployment.yaml`**: Defines your application's pods.
* **`service.yaml`**: Defines how your application's pods are accessed internally.
* **`ingress.yaml`**: Defines how your application is exposed externally via Nginx Ingress and HTTPS.

### Example Manifest Structure

```bash
my-new-app-repo/
├── src/
├── Dockerfile
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml  # Your application's dedicated Ingress
│   └── http-ingress.yaml  # Http validation
├── build-release.sh # Script to build and push Docker image
└── README.md
```

### Template for New Manifests:

Ensure `namespace`, `image`, `containerPort`, `name`, `host(s)`, `service.name`, `service.port` match your app and domain

- `kubernetes/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-landing-page-deployment
  namespace: ingress-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-landing-page
  template:
    metadata:
      labels:
        app: my-landing-page
    spec:
      containers:
        - name: my-landing-page-container
          image: luis122448/my-landing-page:v1.0.0
          ports:
            - containerPort: 4000
```

- `kubernetes/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-landing-page-service
  namespace: ingress-nginx
spec:
  type: ClusterIP
  selector:
    app: my-landing-page
  ports:
    - protocol: TCP
      port: 4000
      targetPort: 4000
```

- `kubernetes/http-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-landing-page-ingress
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: my-landing-page
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: luis122448-com-suite
spec:
  ingressClassName: nginx
  rules:
  - host: "luis122448.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-landing-page-service
            port:
              number: 4000
  - host: "www.luis122448.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-landing-page-service
            port:
              number: 4000
```

- `kubernetes/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-landing-page-ingress
  namespace: ingress-nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  labels:
    app.kubernetes.io/name: my-landing-page
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: luis122448-com-suite
spec:
  ingressClassName: nginx
  rules:
  - host: "luis122448.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-landing-page-service
            port:
              number: 4000
  - host: "www.luis122448.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-landing-page-service
            port:
              number: 4000
  tls:
  - hosts:
    - luis122448.com
    - www.luis122448.com
    secretName: luis122448-com-tls
```

---
## Update FRP Client (`frpc`) Configuration

Your `frpc` client needs to inform the `frps` server about the new domains it will be tunneling.

- Edit the `frpc-config` ConfigMap in Kubernetes:

```bash
kubectl edit configmap frpc-config -n ingress-nginx
```

- Add your new domain(s) to the customDomains list within the [proxies] section that points to your Nginx Ingress Controller (usually `192.168.100.240`).

```ini
# ... inside data.frpc.toml in the ConfigMap
[[proxies]]
name = "nginx-ingress-http"
type = "http"
localIP = "192.168.100.240"
localPort = 80
customDomains = ["test.luis122448.com", "luis122448.com", "[www.luis122448.com](https://www.luis122448.com)", "your-new-domain.com", "[www.your-new-domain.com](https://www.your-new-domain.com)"] # <--- ADD NEW DOMAINS HERE

[[proxies]]
name = "nginx-ingress-https"
type = "https"
localIP = "192.168.100.240"
localPort = 443
customDomains = ["test.luis122448.com", "luis122448.com", "[www.luis122448.com](https://www.luis122448.com)", "your-new-domain.com", "[www.your-new-domain.com](https://www.your-new-domain.com)"] # <--- ADD NEW DOMAINS HERE
# ...
```

- Restart the frpc-client pod for changes to take effect:

```bash
kubectl delete pod -l app=frpc-client -n ingress-nginx
```

---
### Validate New Domain DNS Resolution

Before applying the Ingress for your new application, it is **CRITICALLY IMPORTANT** to verify that its domain(s) are correctly resolving to your VPS's public IP. This is a prerequisite for Cert-Manager's ACME challenge.

Update your DNS provider: Ensure your new domain(s) (e.g., `your-new-domain.com`, `www.your-new-domain.com`) have `A` records pointing to your **VPS Public IP**.

**Recommendation:** Set DNS TTL (Time To Live) to a short duration (e.g., 60 seconds / 1 minute or 300 seconds / 5 minutes) during initial setup for faster propagation, then increase it later (e.g., 3600 seconds).

### Verify DNS Propagation: Use external and internal tools to confirm resolution.

- **External Verification**:

```bash
dig your-new-domain.com
dig [www.your-new-domain.com](https://www.your-new-domain.com) # If applicable
```

Use online tools like [https://www.whatsmydns.net/](https://www.whatsmydns.net/) to check global propagation.

- **Internal Cluster Verification:** From a debug pod within your Kubernetes cluster, ensure the domain resolves.

```bash
kubectl run -it --rm --restart=Never debug-dns --image=busybox:latest -- nslookup your-new-domain.com
# Expected: Should show your VPS Public IP
```

- **If DNS does not resolve:** You MUST wait for propagation or correct your DNS provider settings before proceeding. If CoreDNS cache is suspected, `kubectl rollout restart -n kube-system deployment/coredns`.

---
## Apply Ingress Manifest (HTTP Validation First)

After successful DNS resolution and application deployment, apply the Ingress. For new domains, it's a good practice to initially apply the Ingress **without** the `tls` section and `cert-manager` annotations to validate basic HTTP connectivity through the FRP tunnel.

### Create your Ingress Manifest (e.g., `kubernetes/http-ingress.yaml`):

* Include your application's `host` rules pointing to its `Service`.
* **Crucial:** Do NOT include the `tls` section or `cert-manager` annotations at this stage.

- Apply Ingress Manifest:

```bash
kubectl apply -f ./kubernetes/http-ingress.yaml
```

- Verify HTTP Access (Crucial Prerequisite Check):

```bash
curl -v [http://your-new-domain.com](http://your-new-domain.com)
curl -v [http://www.your-new-domain.com](http://www.your-new-domain.com) # If applicable
```

* **Expected:** An HTTP `200 OK` response with your application's content.
* **If you get an `frp` 404:** Your `frpc.toml` is likely missing the new domain(s) in `customDomains`. Update `frpc-config` ConfigMap and restart `frpc-client` pod.
* **If you get an Nginx 503:** Your application's Service or Deployment is misconfigured (pods not `Running`/`Ready`, Service `Endpoints` missing).

---
## Configure Ingress for HTTPS

Once HTTP access is confirmed through the tunnel, update your Ingress for HTTPS with `cert-manager`. This involves replacing the HTTP-only Ingress with the final HTTPS-enabled one.

### Delete the HTTP-only Ingress:

- It's important to remove the HTTP-only Ingress before applying the HTTPS one to avoid conflicts.**

```bash
kubectl delete -f ./kubernetes/http-ingress.yaml
```

### Create and Apply your final HTTPS-enabled Ingress Manifest (`kubernetes/ingress.yaml`):

* This manifest **replaces** the `ingress.yaml`.
* Include `cert-manager.io/cluster-issuer` annotation.
* Add `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"` annotation.
* Add the `tls` section, specifying hosts and `secretName`.

```yaml
# kubernetes/ingress.yaml (HTTPS Enabled)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: my-new-app-ingress
    namespace: ingress-nginx
    annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod # Your configured ClusterIssuer
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true" # Forces HTTP to HTTPS redirect
    labels:
    app.kubernetes.io/name: my-new-app
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: your-project-suite
spec:
    ingressClassName: nginx
    rules:
    - host: "your-new-domain.com"
    http:
        paths:
        - path: /
        pathType: Prefix
        backend:
            service:
            name: my-new-app-service
            port:
                number: 8080
    - host: "[www.your-new-domain.com](https://www.your-new-domain.com)" # If applicable
    http:
        paths:
        - path: /
        pathType: Prefix
        backend:
            service:
            name: my-new-app-service
            port:
                number: 8080
    tls: # TLS/HTTPS configuration
    - hosts:
    - your-new-domain.com
    - [www.your-new-domain.com](https://www.your-new-domain.com) # Include if applicable
    secretName: your-new-domain-tls # Cert-manager will store the certificate here
```

- Apply the updated Ingress Manifest:

```bash
kubectl apply -f ./kubernetes/ingress.yaml
```

---
## Monitor Certificate Issuance

`cert-manager` will automatically detect the updated Ingress and start the process for obtaining the TLS certificate(s).

- Monitor `Certificate` status:**

```bash
kubectl get certificate -n ingress-nginx -w # Watch for your-new-domain-tls to become READY: True
```

- Monitor `cert-manager` controller logs (for debugging if `False`):**

```bash
kubectl logs -f -n cert-manager $(kubectl get pod -n cert-manager -l app.kubernetes.io/name=cert-manager -o jsonpath='{.items[0].metadata.name}')
```

(Look for `Created Order`, `Created Challenge`, or `Warning Failed` messages related to your domain).

- Verify `Challenge` resources:

```bash
kubectl get challenge -n ingress-nginx -l cert-manager.io/certificate-name=your-new-domain-tls # Check Challenge status
```

* **Expected:** `Challenge` resources go from `pending` to `valid`. `Certificate` status changes from `False` to `True`.
* **Common errors here:**
  * `wrong status code '404', expected '200'`: Your Ingress is routing the challenge request to your application. Revisit `nginx.ingress.kubernetes.io/location-snippet` in your Ingress if needed for debugging.
  * `dial tcp: lookup ... no such host`: DNS resolution inside cluster is failing for this domain. Re-check DNS TTL and CoreDNS restart.

---
## Final Verification of Access

Once the `Certificate` is `READY: True`.

- Verify HTTPS access:

```bash
curl -v [https://your-new-domain.com](https://your-new-domain.com)
curl -v [https://www.your-new-domain.com](https://www.your-new-domain.com) # If applicable
```
- Verify HTTP to HTTPS redirection:

```bash
curl -v [http://your-new-domain.com](http://your-new-domain.com)
curl -v [http://www.your-new-domain.com](http://www.your-new-domain.com) # If applicable
```