# Guide: Implementing the HashiCorp Vault CSI Driver

This guide provides a comprehensive walkthrough for setting up the HashiCorp Vault CSI driver on your Kubernetes cluster. This method is considered a best practice for secret management as it avoids creating Kubernetes Secret objects entirely.

## 1. Prerequisites

Before you begin, ensure you have the following:

1.  A running Kubernetes cluster.
2.  `kubectl` configured to communicate with your cluster.
3.  `helm` v3 installed.
4.  A running HashiCorp Vault instance.
5.  The Vault Kubernetes authentication method enabled and configured.

---

## 2. Installation

The Vault CSI driver is installed using the official `hashicorp/vault` Helm chart. We will use a custom values file to disable the Vault server deployment and enable only the CSI provider components.

### Step 2.1: Add the HashiCorp Helm Repository

If you haven't already, add and update the HashiCorp Helm repo:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

### Step 2.2: Install the Vault CSI Driver

This command installs the CSI provider into the `kube-system` namespace. It uses the `csi-provider-values.yaml` file (which should be in this directory) to specify that only the CSI provider should be enabled.

```bash
helm install vault-csi-provider hashicorp/vault -f csi-provider-values.yaml --namespace kube-system
```

**Contents of `csi-provider-values.yaml`:**

```yml
# This values file tells the official HashiCorp Vault Helm chart
# to ONLY install the CSI provider components and not the Vault server itself.
csi:
  enabled: true

server:
  enabled: false
```

### Step 2.3: Verify the Installation

Check that the CSI driver pods are running. You should see one `vault-csi-provider` pod for each node in your cluster.

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=vault-csi-provider
```

---

## 3. Vault Configuration

Next, you need to configure a secret, a policy, and a role in Vault for a sample application.

### Step 3.1: Create a Test Secret

We will use a simple username/password secret for this example.

```bash
vault kv put cluster/csi-test username="luis122448" password="***********"
```

### Step 3.2: Create a Vault Policy

This policy grants read-only access to the secret we just created.

```bash
vault policy write csi-test-policy - <<EOF
{
  "path": {
    "kv/data/cluster/csi-test": {
      "capabilities": ["read"]
    }
  }
}
EOF

```

### Step 3.3: Create a Kubernetes Authentication Role

This role ties the Kubernetes Service Account of our future application to the Vault policy.

```bash
vault write auth/kubernetes/role/csi-test \
    bound_service_account_names=csi-test-sa \
    bound_service_account_namespaces=csi-test \
    policies=csi-test-policy \
    ttl=24h
```

---

## 4. Kubernetes Manifests

Now, we will create the Kubernetes resources for a sample application that will consume the secret.

### `SecretProviderClass`

This is the most important resource. It tells the CSI driver which Vault instance to connect to, which role to use, and which secrets to fetch.

*See the accompanying `02-secret-provider-class.yaml` file.*

### Application Deployment

The Deployment manifest has three key sections for the CSI driver:

1.  `spec.template.spec.volumes`: Defines a volume of type `csi` that references our `SecretProviderClass`.
2.  `spec.template.spec.containers.volumeMounts`: Mounts the CSI volume into the container at a specified path (e.g., `/mnt/secrets-store`).
3.  `spec.template.spec.securityContext`: **Crucially**, we run the pod as a non-root user. This is what prevents even a user with `kubectl exec` (as root) from reading the secret file.

*See the accompanying `03-app-deployment.yaml` file.*

---

## 5. Deployment and Verification

### Step 5.1: Apply the Manifests

Apply all the provided example manifests.

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-service-account.yaml
kubectl apply -f 02-secret-provider-class.yaml
kubectl apply -f 03-app-deployment.yaml
```

### Step 5.2: Verify Secret Mounting

Once the pod is running, `exec` into it to check if the secret was mounted correctly.

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -n csi-test -l app=csi-test -o jsonpath='{.items[0].metadata.name}')

# Exec into the pod as the application user (UID 1000)
kubectl exec -it $POD_NAME -n csi-test -- /bin/sh
```

Inside the pod, you are now user `appuser`. Try to read the secret:

```sh
# This should succeed and print the content of the secret
cat /mnt/secrets-store/credentials.properties

# Exit the shell
exit
```

### Step 5.3: Verify Security (The Magic)

Now, `exec` into the same pod, but this time as the `root` user.

```bash
kubectl exec -it --user=root $POD_NAME -n csi-test -- /bin/sh
```

Inside the pod, you are now `root`. Try to read the secret file:

```sh
# This command will FAIL with "Permission denied"
cat /mnt/secrets-store/credentials.properties
```

This demonstrates the power of the CSI driver. Because the secret file is owned by `appuser` (UID 1000) with permissions `0600`, not even the `root` user can read it. You have successfully isolated the secret to the application process itself.

```