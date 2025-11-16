# Kubernetes External User Access Setup Guide

This guide provides the step-by-step process for creating a new user with access restricted to a specific namespace in the Kubernetes cluster. This method uses client certificates for authentication and RBAC (Role-Based Access Control) for authorization.

## Prerequisites

- `kubectl` installed and configured with administrative access to the Kubernetes cluster.
- `openssl` command-line tool installed.

---

## Step 1: Define User and Namespace

First, decide on a username and the namespace they will have access to. For this guide, we will use:

-   **Username**: `external-dev`
-   **Namespace**: `dev-namespace`
-   **Role**: `developer-role`

You can change these values in the commands below.

```bash
# Set variables for easier execution
export K8S_USER="external-dev"
export K8S_NAMESPACE="dev-namespace"
```

---

## Step 2: Create the Namespace

If the namespace doesn't already exist, create it.

```bash
kubectl create namespace "${K8S_NAMESPACE}"
```

---

## Step 3: Generate User's Private Key and CSR

Create a private key and a Certificate Signing Request (CSR) for the new user. The `CN` (Common Name) in the subject will be the username, and `O` (Organization) will be the group.

```bash
# Generate a 2048-bit RSA private key
openssl genrsa -out "${K8S_USER}.key" 2048

# Create a CSR
# The CN becomes the username in Kubernetes.
# The O becomes the group.
openssl req -new -key "${K8S_USER}.key" -out "${K8S_USER}.csr" -subj "/CN=${K8S_USER}/O=external-developers"
```

---

## Step 4: Approve the Certificate in Kubernetes

Submit the CSR to the cluster and approve it.

```bash
# Create a CertificateSigningRequest object in Kubernetes
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${K8S_USER}-csr
spec:
  request: $(cat ${K8S_USER}.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# Approve the CSR
kubectl certificate approve "${K8S_USER}-csr"

# Extract the signed certificate from the cluster
kubectl get csr "${K8S_USER}-csr" -o jsonpath='{.status.certificate}' | base64 --decode > "${K8S_USER}.crt"
```
After this step, you will have the user's signed certificate (`${K8S_USER}.crt`).

---

## Step 5: Define User Permissions (Role & RoleBinding)

With the user identity created, we now define what they are allowed to do. We use a `Role` to define permissions and a `RoleBinding` to grant those permissions to the user.

The template YAML files `01-developer-role.yml` and `02-developer-rolebinding.yml` are provided in this directory.

1.  **Customize the templates**: If necessary, open the YAML files and adjust the `namespace` or the user `name` to match your variables. The provided templates are already set up for the `dev-namespace` and `external-dev` user.

2.  **Apply the Role and RoleBinding**:
    ```bash
    # Apply the role that defines permissions
    kubectl apply -f 01-developer-role.yml
    
    # Apply the binding that links the user to the role
    kubectl apply -f 02-developer-rolebinding.yml
    ```

---

## Step 6: Generate the User's kubeconfig File

This final step packages the cluster connection info, the user's certificate, and the user's key into a single `kubeconfig` file to be delivered to the developer.

```bash
# --- Configuration ---
# Get cluster details from your current kubectl context
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config get-contexts $CURRENT_CONTEXT --no-headers | awk '{print $3}')
CA_DATA=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.certificate-authority-data}")
RAW_SERVER_URL=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.server}")

# --- IMPORTANT ACTION REQUIRED ---
# Replace the internal server URL with the public-facing URL (e.g., from your FRP or VPN setup).
# Example: SERVER_URL="https://k8s-api.your-domain.com:6443"
SERVER_URL=${RAW_SERVER_URL} 
# -------------------------

# --- Generate the file ---
KUBECONFIG_FILENAME="kubeconfig-${K8S_USER}.yaml"

cat <<EOF > ${KUBECONFIG_FILENAME}
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_DATA}
    server: ${SERVER_URL}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${K8S_NAMESPACE}
    user: ${K8S_USER}
  name: ${K8S_USER}-context
current-context: ${K8S_USER}-context
users:
- name: ${K8S_USER}
  user:
    client-certificate-data: $(cat ${K8S_USER}.crt | base64 | tr -d '\n')
    client-key-data: $(cat ${K8S_USER}.key | base64 | tr -d '\n')
EOF

echo "Generated kubeconfig file: ${KUBECONFIG_FILENAME}"
```

---

## Step 7: Deliver and Test

Securely send the generated `kubeconfig-external-dev.yaml` file to the developer. They can use it by setting the `KUBECONFIG` environment variable.

**Developer's Test Commands:**

```bash
# Point to the new config file
export KUBECONFIG=/path/to/kubeconfig-external-dev.yaml

# 1. This command should SUCCEED
# It will list pods in their assigned namespace.
kubectl get pods

# 2. This command should FAIL
# It tries to access a different namespace, which the role does not allow.
kubectl get pods --namespace=default
# Expected output: Error from server (Forbidden): pods is forbidden...
```

---

## Cleanup

You can now safely delete the `.key` and `.csr` files. The final `.crt` file content is embedded in the kubeconfig file.

```bash
# rm external-dev.key external-dev.csr external-dev.crt
```
