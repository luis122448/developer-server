# Guide: Using AWS Secrets Manager with a Self-Hosted Kubernetes Cluster

This guide explains how to use AWS Secrets Manager as the source for your TLS certificates in a self-hosted or non-EKS Kubernetes cluster. This approach uses a dedicated IAM User for authentication and the External Secrets Operator (ESO) to sync the certificates.

--- 

## Step 1: Create the IAM User and Policy in AWS

First, we need a dedicated IAM user with the absolute minimum permissions required.

1.  **Create an IAM Policy**:

*   Navigate to IAM -> Policies -> Create policy.
*   Using the JSON editor, paste the following policy. This grants read-only access to specific secrets.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
                "arn:aws:secretsmanager:YOUR_REGION:YOUR_ACCOUNT_ID:secret:prod/tls/secret-one-name*",
                "arn:aws:secretsmanager:YOUR_REGION:YOUR_ACCOUNT_ID:secret:prod/tls/secret-two-name*"
            ]
        }
    ]
}
```
*   **IMPORTANT**: The `*` at the end of each resource ARN is crucial. It ensures the policy matches the unique ID that AWS appends to each secret. Replace the example ARNs with the actual names of your secrets.

1.  **Create an IAM User**: Create a user (e.g., `external-secrets-user`) and attach the policy you just created.

2.  **Generate Access Keys**: For this user, create an `Access Key ID` and a `Secret Access Key` and copy them securely.

## Step 2: Install and Configure External Secrets Operator (ESO)

1.  **Create the Namespace** for the operator:

```bash
kubectl create namespace external-secrets
```

2.  **Install Custom Resource Definitions (CRDs)**:

This critical step teaches your cluster what `SecretStore` and `ExternalSecret` objects are. The official ESO documentation provides the most up-to-date command.
*   **Official Docs**: [https://external-secrets.io/latest/](https://external-secrets.io/latest/)
*   **Getting Started Guide**: [https://external-secrets.io/latest/introduction/getting-started/](https://external-secrets.io/latest/introduction/getting-started/)

The command will look like this (check the docs for the latest version):

```bash
kubectl apply -f https://github.com/external-secrets/external-secrets/releases/download/v0.9.9/crds.yaml
```

3.  **Verify CRD Installation**:

Confirm the `SecretStore` resource is known to the cluster. Run:

```bash
kubectl api-resources | grep secretstore
```

You MUST see a line like this. If the command returns nothing, do not proceed.

```
secretstores     ss      external-secrets.io/v1      true         SecretStore
```

4.  **Install ESO with Helm**:

Install the operator itself, telling Helm to skip the CRDs we just installed manually.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --set installCRDs=false
```

## Step 3: Provide AWS Credentials to ESO

1.  **Create the Credentials File**:

Create a file named `aws-credentials-secret.yaml` with the keys from Step 1.

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

2.  **Apply and Verify the Secret**:

Apply the secret to the cluster. Then, as a **mandatory verification step**, decode the secret to ensure there were no copy-paste errors.

```bash
# Apply the secret
kubectl apply -f frp/cert-manager/manual-aws/aws-credentials-secret.yaml

# Verify the Access Key ID
kubectl get secret aws-eso-credentials -n external-secrets -o jsonpath='{.data.accessKeyID}' | base64 --decode
```

The output MUST exactly match the Access Key ID you pasted. If not, delete the secret, fix the file, and re-apply.

## Step 4: Configure Secret Access (Choose One Method)

Here you decide how `ExternalSecret` resources will find their configuration.

### Method A: ClusterSecretStore (Recommended)

Use this method to create a single, central store that any `ExternalSecret` in any namespace can use. This is the cleanest and most scalable approach.

1.  **Create `aws-cluster-secret-store.yaml`**:

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: aws-cluster-secret-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: YOUR_REGION
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-eso-credentials
            key: accessKeyID
            namespace: external-secrets
          secretAccessKeySecretRef:
            name: aws-eso-credentials
            key: secretAccessKey
            namespace: external-secrets
```

1.  **Apply it**:

```bash
kubectl apply -f frp/cert-manager/manual-aws/aws-cluster-secret-store.yaml
```

### Method B: SecretStore (Namespace-Scoped)

Use this if you need a specific store for a single namespace.

1.  **Create `aws-secret-store.yaml`**:

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
      region: YOUR_REGION
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-eso-credentials
            key: accessKeyID
          secretAccessKeySecretRef:
            name: aws-eso-credentials
            key: secretAccessKey
```

1.  **Apply it**:

```bash
kubectl apply -f frp/cert-manager/manual-aws/aws-secret-store.yaml
```

## Step 5: Create the TLS Secret in Kubernetes

Finally, create the `ExternalSecret` resource. This will trigger ESO to fetch the data from AWS and create a native Kubernetes `Secret`.

1.  **Create `nginx-test-external-secret.yaml`**:
    
This file tells ESO what to fetch and how to create the final secret. Note how `secretStoreRef` points to the store we created.

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  # The name of the Kubernetes Secret that will be created.
  # This should match the secretName in your Ingress resource.
  name: nginx-test-tls-secret
  namespace: ingress-nginx
spec:
  # The SecretStore to use. We will create this in the setup guide.
  secretStoreRef:
    name: aws-cluster-secret-store
    kind: ClusterSecretStore

  # This is the name of the Kubernetes Secret that will be created.
  # It should match the 'name' in the metadata section.
  target:
    name: nginx-test-tls-secret
    # This ensures the Secret is of the correct type for Ingress controllers.
    creationPolicy: Owner
    template:
      type: kubernetes.io/tls

  # This section defines which secret to fetch from AWS Secrets Manager
  # and how to map its keys to the Kubernetes Secret.
  data:
  - secretKey: tls.key # The key in the resulting k8s Secret (standard for TLS secrets)
    remoteRef:
      key: prod/tls/luis122448.dev # The name of your secret in AWS Secrets Manager
      property: privkey      # The key within the JSON of your AWS secret

  - secretKey: tls.crt # The key in the resulting k8s Secret (standard for TLS secrets)
    remoteRef:
      key: prod/tls/luis122448.dev # The name of your secret in AWS Secrets Manager
      property: fullchain       # The key within the JSON of your AWS secret
```

2.  **Apply it in your application's namespace**:

```bash
kubectl apply -f frp/cert-manager/manual-aws/nginx-test-external-secret.yaml
```

3.  **Verify the final result**:

```bash
# Check the status of the ExternalSecret
watch kubectl get externalsecret frp-tls-secret

# Check that the native k8s secret was created
kubectl get secret frp-tls-secret
```

Your Ingress can now reference `secretName: frp-tls-secret`.
