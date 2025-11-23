# User and Permission Creation for Developer

This guide details how to create a `ServiceAccount` for a developer, grant it full permissions on a specific namespace (`erp-tsi-test`), and finally, how to generate the `kubeconfig` file for remote connection.

## Step 1: Create the Namespace

If the `erp-tsi-test` namespace does not exist, create it with the following command:

```bash
kubectl create namespace erp-tsi-test
```

## Step 2: Define Role, ServiceAccount, and RoleBinding

Create a file named `developer-access.yaml` with the following content. This manifest defines:
- **ServiceAccount**: `developer-user` - The developer's "identity" within the `erp-tsi-test` namespace.
- **Role**: `developer-role` - Defines the permissions (full access to all resources) within the `erp-tsi-test` namespace.
- **RoleBinding**: `developer-role-binding` - Associates the `ServiceAccount` with the `Role`.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer-user
  namespace: erp-tsi-test
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: erp-tsi-test
rules:
- apiGroups: ["", "apps", "extensions", "batch", "networking.k8s.io", "storage.k8s.io", "apiextensions.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-role-binding
  namespace: erp-tsi-test
subjects:
- kind: ServiceAccount
  name: developer-user
  namespace: erp-tsi-test
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

## Step 3: Apply the Configuration

Apply the manifest to create the resources in the cluster:

```bash
kubectl apply -f developer-access.yaml
```

## Step 4: Generate an Access Token

Generate a long-lived token (e.g., 1 year) for the `ServiceAccount`. The developer will use this token to authenticate.

```bash
kubectl create token developer-user -n erp-tsi-test --duration=8760h
```

Copy the generated token; you will need it for the next step.

## Step 5: Create the `kubeconfig` File

Create a `kubeconfig.dev` file on the developer's machine. This file will allow `kubectl` to connect to the cluster through the FRP tunnel.

**Important:** The `insecure-skip-tls-verify: true` setting is necessary because the API Server's certificate will not match the public domain of FRPS. This is convenient for development but **insecure for production**, as it disables server certificate verification.

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://YOUR_FRPS_DOMAIN:REMOTE_PORT
  name: private-cluster
contexts:
- context:
    cluster: private-cluster
    namespace: erp-tsi-test
    user: developer-user
  name: dev-context
current-context: dev-context
users:
- name: developer-user
  user:
    token: "PASTE_GENERATED_TOKEN_HERE"
```

**Instructions for the developer:**
1. Replace `YOUR_FRPS_DOMAIN:REMOTE_PORT` with your FRP server's domain and the port you configured in `frpc.toml` (e.g., `myfrps.com:6443`).
2. Replace `PASTE_GENERATED_TOKEN_HERE` with the token you obtained in the previous step.

## Step 6: Test the Connection

The developer can now test the connection to their namespace using the new `kubeconfig`.

```bash
kubectl --kubeconfig=./kubeconfig.dev get pods
```

If everything is configured correctly, this command should return the list of pods in the `erp-tsi-test` namespace without errors.