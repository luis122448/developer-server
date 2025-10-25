# Deploying Harbor to Kubernetes with Helm

This guide documents the steps to install Harbor on a Kubernetes cluster using its official Helm chart.

## Prerequisites

1.  **Kubernetes Cluster**: You must have an active K8s cluster and `kubectl` configured to access it.
2.  **Helm**: Helm v3 must be installed on your local machine.
3.  **Ingress Controller**: It is highly recommended to have an Ingress Controller (like NGINX, Traefik, etc.) already installed in the cluster. This is necessary to expose Harbor securely.
4.  **StorageClass**: Your cluster must have a default `StorageClass`, or you must specify one for data persistence. This is crucial so that Harbor's data (images, database) is not lost if the pods restart.

---

## Installation Steps

### Step 1: Add the Harbor Helm Repository

This command adds the official Harbor repository to your Helm configuration.

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### Step 2: Create a Namespace

It is good practice to install Harbor in its own namespace to keep the cluster organized.

```bash
kubectl create namespace harbor
```

### Step 3: Configure Harbor (`values.yaml`)

Harbor's configuration is managed through a `values.yaml` file. I have created a `values.template.yaml` file in this same directory with a basic configuration.

**Required Action:**
1.  Copy `values.template.yaml` to a new file named `my-values.yaml`.
2.  **Edit `my-values.yaml`** and fill in the values marked as `CHANGE_ME`, especially:
    *   The `hostname` to access Harbor.
    *   The administrator password (`harborAdminPassword`).
    *   Your `ingressClassName`.
    *   The persistence settings if you are not using the default `StorageClass`.

### Step 4: Install Harbor with Helm

Once your `my-values.yaml` file is ready, run the following command to deploy Harbor.

This command installs the chart named `harbor` from the `harbor` repository into the `harbor` namespace, using your configuration file.

```bash
helm install harbor harbor/harbor --namespace harbor -f my-values.yaml
```

### Step 5: Verify the Installation

The deployment may take several minutes as it needs to download all the images and wait for the services to start in the correct order.

You can watch the status of the pods with:

```bash
kubectl get pods -n harbor -w
```

Wait until all pods are in the `Running` or `Completed` state.

### Step 6: DNS Configuration

After everything is running, you must configure your DNS so that the `hostname` you chose in the `values.yaml` points to the external IP address of your Ingress Controller.

Once this is done, you will be able to access the Harbor UI at `https://<your-hostname>`.