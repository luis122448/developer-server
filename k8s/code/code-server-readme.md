# Deploy code-server on Kubernetes using Manifests

This guide provides the steps to deploy a custom `code-server` instance on your Kubernetes cluster.

## 1. Prerequisites

### 1.1. Build and Push the Custom Docker Image
Before deploying, you must build the custom `code-server` image and push it to your Harbor registry.

**The instructions for this are in the `docker/code-server/README.md` file. Please complete those steps first.**

### 1.2. Create Kubernetes Secrets
This deployment requires two secrets to be present in the `code-server` namespace.

**Harbor Secret (if not already created):**
This secret is used to pull the custom image from your private Harbor registry.
```bash
kubectl create secret docker-registry harbor-secrets \
  --docker-server=harbor.bbg.pe \
  --docker-username=<YOUR_HARBOR_USERNAME> \
  --docker-password=<YOUR_HARBOR_PASSWORD_OR_TOKEN> \
  --namespace=code-server
```

**DeepSeek API Key Secret:**
This secret securely stores your DeepSeek API key, which will be injected into the `code-server` pod as an environment variable.
```bash
kubectl create secret generic deepseek-api-key \
  --from-literal=key='your_api_key_here' \
  --namespace=code-server
```
**Important:** Replace `your_api_key_here` with your actual DeepSeek API key.

## 2. Manifest File

The `code-server-manifest.yml` file is configured to use your custom image and the secrets you created.

## 3. Deploy the Application

Once your custom image is in Harbor and the secrets are created, apply the manifest file:

```bash
kubectl apply -f k8s/code/code-server-manifest.yml
```

## 4. Access code-server

Once the pod is running (check with `kubectl get pods -n code-server`), you can access your instance at:

**https://code.bbg.pe**

Use the password `YOUR_HARBOR_PASSWORD` to log in. Inside the terminal, the `DEEPSEEK_API_KEY` environment variable will be available.

## 5. Uninstalling

To remove the deployment, run:

```bash
kubectl delete -f k8s/code/code-server-manifest.yml
```
