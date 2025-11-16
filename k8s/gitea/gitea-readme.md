# Gitea on Kubernetes

This guide describes the steps to deploy Gitea on a Kubernetes cluster, using a PostgreSQL database.

**Requirements:**
- A functional Kubernetes cluster.
- `kubectl` installed and configured.
- An Ingress Controller (NGINX) installed.
- A `StorageClass` named `nas-003` must be available in the cluster.
- (Optional but recommended) `cert-manager` for automatic TLS certificate management.

---

## 1. Deployment Manifest (gitea.yaml)

Create a file named `gitea.yaml`. This manifest contains all the necessary resources for Gitea and its PostgreSQL database.

- **Namespace:** Isolates Gitea resources in its own namespace.
- **PersistentVolumeClaims (PVC):** Two PVCs requesting storage from `StorageClass: nas-003`, one for Gitea data and one for the database.
- **PostgreSQL:** A PostgreSQL deployment with its respective `Service` and a `Secret` for credentials.
- **Gitea:** The main Gitea deployment, configured to use the PostgreSQL database.
- **Service:** Exposes Gitea internally within the cluster.
- **Ingress:** Exposes Gitea externally through the `git.bbg.pe` domain.

```yaml
# gitea.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gitea
---
apiVersion: v1
kind: Secret
metadata:
  name: gitea-db-secret
  namespace: gitea
type: Opaque
stringData:
  POSTGRES_USER: gitea
  POSTGRES_PASSWORD: "CHANGE_ME_TO_A_STRONG_PASSWORD"
  POSTGRES_DB: gitea
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-db-pvc
  namespace: gitea
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nas-003
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: gitea
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:13
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 5432
          envFrom:
            - secretRef:
                name: gitea-db-secret
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgredb
      volumes:
        - name: postgredb
          persistentVolumeClaim:
            claimName: gitea-db-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: gitea
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-data-pvc
  namespace: gitea
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nas-003
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: gitea
  labels:
    app: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      containers:
        - name: gitea
          image: gitea/gitea:latest
          imagePullPolicy: "IfNotPresent"
          env:
            - name: GITEA__database__DB_TYPE
              value: "postgres"
            - name: GITEA__database__HOST
              value: "postgres:5432"
            - name: GITEA__database__NAME
              valueFrom:
                secretKeyRef:
                  name: gitea-db-secret
                  key: POSTGRES_DB
            - name: GITEA__database__USER
              valueFrom:
                secretKeyRef:
                  name: gitea-db-secret
                  key: POSTGRES_USER
            - name: GITEA__database__PASSWD
              valueFrom:
                secretKeyRef:
                  name: gitea-db-secret
                  key: POSTGRES_PASSWORD
            - name: GITEA__server__DOMAIN
              value: "git.bbg.pe"
            - name: GITEA__server__ROOT_URL
              value: "https://git.bbg.pe"
            - name: GITEA__server__SSH_DOMAIN
              value: "git.bbg.pe"
            - name: GITEA__server__SSH_PORT
              value: "22"
            - name: GITEA__service__DISABLE_REGISTRATION
              value: "false" # Change to true after creating the first user
          ports:
            - containerPort: 3000
              name: gitea-http
            - containerPort: 22
              name: gitea-ssh
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: gitea-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: gitea
  namespace: gitea
spec:
  selector:
    app: gitea
  ports:
    - name: http
      port: 3000
      targetPort: 3000
    - name: ssh
      port: 22
      targetPort: 22
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitea-ingress
  namespace: gitea
  annotations:
    # Ensure the Ingress Class is correct for your cluster
    kubernetes.io/ingress.class: "nginx"
    # Annotations for cert-manager (optional)
    cert-manager.io/cluster-issuer: "letsencrypt-prod" # Replace with your ClusterIssuer
spec:
  tls:
  - hosts:
    - git.bbg.pe
    secretName: gitea-tls # cert-manager will create this secret
  rules:
  - host: git.bbg.pe
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gitea
            port:
              number: 3000
```

---

## 2. Deploy Gitea

Apply the `gitea.yaml` manifest to create all resources in the cluster.

```bash
kubectl apply -f gitea.yaml
```

---

## 3. Verification and Access

1.  **Verify Pods:**
Ensure that the Gitea and PostgreSQL pods are in a `Running` state.

```bash
kubectl get pods -n gitea -w
```

2.  **Verify Ingress:**
Check that the Ingress has been created correctly and has an IP address assigned.

```bash
kubectl get ingress -n gitea
```

3.  **Access Gitea:**
Once the Ingress has an IP and DNS propagation is complete, you can access Gitea via your browser at `https://git.bbg.pe`.

4.  **Initial Configuration:**
- The first time you access it, Gitea will present an installation screen.
- The database configuration is already pre-configured via environment variables.
- **Important:** Ensure that the "Gitea Server Domain" and "Gitea Base URL" are configured as `git.bbg.pe` and `https://git.bbg.pe` respectively.
- Create your administrator account.
- After creating the administrator, it is recommended to disable public registration. You can do this by changing the `GITEA__service__DISABLE_REGISTRATION` environment variable to `true` in the Gitea `Deployment` and reapplying the changes.

---

## Helm Chart Installation (Recommended Method)

Using the official Gitea Helm chart is a faster and more manageable way to deploy Gitea. It simplifies configuration, upgrades, and dependency management.

### 1. Add Gitea Helm Repository

First, add the Gitea chart repository to your Helm client:

```bash
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
```

### 2. Create `gitea-template.yml`

Create a file named `gitea-template.yml` to customize the installation. This file will configure the Ingress, domain, and storage settings.

```yaml
# gitea-template.yml

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod" # Replace with your ClusterIssuer
  hosts:
    - host: git.bbg.pe
      paths:
        - path: /
          pathType: Prefix
  tls:
   - secretName: gitea-tls
     hosts:
       - git.bbg.pe

# Gitea main configuration
gitea:
  config:
    server:
      ROOT_URL: https://git.bbg.pe
      DOMAIN: git.bbg.pe
      SSH_DOMAIN: git.bbg.pe
    service:
      DISABLE_REGISTRATION: false # Change to true after creating the first user
  
  # Configure persistence for Gitea data
  persistence:
    enabled: true
    storageClassName: nas-003
    size: 20Gi

# Use the PostgreSQL sub-chart included with the Gitea chart
postgresql:
  enabled: true
  # Configure persistence for PostgreSQL data
  persistence:
    storageClassName: nas-003
    size: 10Gi
  postgresqlPassword: ""
```

### 3. Install the Chart

Now, deploy Gitea using `helm install`. This command will create all the necessary resources in the `gitea` namespace.

```bash
# Create the namespace first if it doesn't exist
kubectl create namespace gitea --dry-run=client -o yaml | kubectl apply -f -

# Install the chart
helm install gitea gitea-charts/gitea \
  --namespace gitea \
  -f gitea-template.yml
```

### 4. Access Gitea

After the installation is complete, you can access Gitea at `https://git.bbg.pe`. The initial setup is handled automatically by the Helm chart based on the `gitea-template.yml` file.

---

## Uninstalling Gitea

To completely remove Gitea and all its associated resources, follow these steps.

### 1. Uninstall the Helm Release

First, uninstall the Helm release. This will remove all the Kubernetes resources created by the chart, such as Deployments, Services, and Ingress.

```bash
helm uninstall gitea --namespace gitea
```

### 2. Delete the Namespace

Next, delete the `gitea` namespace to clean up any remaining resources.

```bash
kubectl delete namespace gitea
```

### 3. Clean Up Persistent Data (Optional)

By default, the Persistent Volume Claims (PVCs) created for Gitea and PostgreSQL might not be deleted when the namespace is removed, depending on the `reclaimPolicy` of your StorageClass. This is a safety measure to prevent accidental data loss.

If you want to permanently delete all data, you must also delete the PVCs.

1.  **Check for remaining PVCs:**

```bash
kubectl get pvc -n gitea
```

2.  **Delete the PVCs if they still exist:**
    
```bash
# This command will delete all PVCs in the gitea namespace
kubectl delete pvc --all -n gitea
```

**Warning:** This action is irreversible and will result in the permanent loss of all your Gitea and database data.