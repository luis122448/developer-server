# Guide: Using AWS Secrets Manager with a Self-Hosted Kubernetes Cluster

This guide explains how to use AWS Secrets Manager as the source for your TLS certificates in a self-hosted or non-EKS Kubernetes cluster. This approach uses a dedicated IAM User for authentication and the External Secrets Operator (ESO) to sync the certificates.

## Architecture

1.  **AWS Secrets Manager**: Securely stores the TLS certificate.
2.  **Dedicated IAM User**: A user in AWS with credentials and restricted permissions.
3.  **Kubernetes Secret**: Holds the IAM user's credentials.
4.  **External Secrets Operator (ESO)**: A Kubernetes operator that reads secrets from AWS.
5.  **SecretStore Resource**: Tells ESO how to authenticate.
6.  **ExternalSecret Resource**: Defines which secret to fetch and what to name the resulting Kubernetes `Secret`.

---

## Prerequisites

1.  An active AWS account.
2.  A running Kubernetes cluster.
3.  `kubectl` and `aws` CLI tools installed and configured.
4.  A TLS certificate with its `private.key` and `fullchain.pem` files.

---

## Step-by-Step Setup

### Step 1: Store Your Certificate in AWS Secrets Manager

1.  Navigate to **AWS Secrets Manager**.
2.  Click **"Store a new secret"** and select `Other type of secret`.
3.  Under **Key/value pairs**:
    *   Row 1: **Key** = `private_key`, **Value** = (paste content of `privkey.pem`).
    *   Row 2: **Key** = `full_chain`, **Value** = (paste content of `fullchain.pem`).
4.  **Secret name**: Give it a name like `prod/tls/midominio.dev`.
5.  Disable automatic rotation and store the secret.

### Step 2: Create a Dedicated IAM User for ESO

1.  **Create an IAM Policy** with `secretsmanager:GetSecretValue` permission for the specific secret ARN you created in Step 1.
2.  **Create an IAM User** and attach this policy.
3.  **Generate an Access Key** for the user and copy the `Access key ID` and `Secret access key`.

### Step 3: Install the External Secrets Operator (ESO)

1.  **Create the Namespace** for the operator:
    
```bash
kubectl create namespace external-secrets
```

2.  **Install Custom Resource Definitions (CRDs)**:

This is a critical step. The following command installs the necessary `SecretStore` and `ExternalSecret` resource definitions into your cluster.

```bash
# Note: This URL points to a specific version. Ensure it is valid and accessible.
kubectl apply -f "https://raw.githubusercontent.com/external-secrets/external-secrets/v0.19.0/deploy/crds/bundle.yaml" --server-side
```

After running this, verify the installation. This command checks if the `SecretStore` resource type is now known to the cluster.

```bash
kubectl api-resources | grep secretstore
```

**You must look for a line in the output that looks like this:**

```
secretstores     ss      external-secrets.io/v1      true         SecretStore
```

This confirms the CRD was installed correctly. If this command returns nothing, do not proceed.

3.  **Install ESO with Helm**:

Now, install the operator itself, but tell Helm not to install CRDs, as we have already done so manually.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --set installCRDs=false
```

### Step 4: Create the Kubernetes Secret for AWS Credentials

Create a Kubernetes `Secret` in the `external-secrets` namespace to hold the IAM user credentials.

Create a file named `aws-credentials-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-eso-credentials
  namespace: external-secrets
type: Opaque
stringData:
  accessKeyID: "YOUR_ACCESS_KEY_ID"
  secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
```

Apply it: `kubectl apply -f aws-credentials-secret.yaml`

### Step 5: Create the SecretStore

The `SecretStore` tells ESO how to authenticate by referencing the secret we just created.

Create a file named `secret-store.yaml`:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: aws-secret-store
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: YOUR_REGION # e.g., us-east-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-eso-credentials
            key: accessKeyID
          secretAccessKeySecretRef:
            name: aws-eso-credentials
            key: secretAccessKey
```

Apply it: `kubectl apply -f secret-store.yaml`

### Step 6: Deploy the ExternalSecret to Create Your TLS Secret

Apply the `external-secret.yaml` manifest to the namespace where your application and Ingress are running (`YOUR_FRP_NAMESPACE`).

```bash
kubectl apply -f frp/cert-manager/manual-aws/nginx-test-external-secret.yaml
```

### Step 7: Verification and Ingress Configuration

1.  **Check for the Kubernetes Secret**:
    
Verify that the `frp-tls-secret` was created in your application's namespace.

```bash
kubectl get externalsecret frp-tls-secret -n external-secrets
```

2.  **Update Your Ingress**:

Ensure your Ingress resource uses this new secret.
    
```yaml
spec:
  tls:
  - hosts:
    - your.domain.dev
    secretName: frp-tls-secret # <-- This must match
```