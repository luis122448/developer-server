# GitLab on Kubernetes

This guide explains how to install GitLab on a Kubernetes cluster using the official GitLab Helm chart.

## Prerequisites

*   A running Kubernetes cluster.
*   `kubectl` installed and configured to connect to your cluster.
*   Helm v3 installed.
*   A domain name for GitLab.

## Installation

1.  **Add the GitLab Helm repository:**

```bash
helm repo add gitlab https://charts.gitlab.io/
helm repo update
```

2.  **Create a namespace for GitLab:**

```bash
kubectl create namespace gitlab
```

3.  **Configure GitLab and SSL Certificate**

Two configuration files are required:

*   `gitlab-template.yml`: Contains the Helm values for the GitLab chart. It's configured to use an externally managed certificate.
*   `unified-certificate.yaml`: A declarative Kubernetes manifest to request a single, unified SSL certificate from cert-manager for all GitLab subdomains.

Ensure both files are configured correctly for your domain.

4.  **Deploy GitLab (Two-Step Process)**

The deployment is a two-step process to ensure the SSL certificate is handled correctly.

**Step 4.1: Apply the Certificate Manifest**

First, apply the unified certificate definition. This tells cert-manager to start provisioning the SSL certificate.

```bash
kubectl apply -f gitlab-certificate.yml
```

You can monitor the status of the certificate with `kubectl describe certificate gitlab-unified-cert -n gitlab`. Wait for the `Ready` status to be `True`.

**Step 4.2: Deploy the GitLab Chart**

Once the certificate is being provisioned, install the GitLab chart. It will find and use the secret created by cert-manager.

```bash
helm install gitlab gitlab/gitlab \
    --namespace gitlab \
    --values gitlab-template.yml
```

This command will deploy GitLab to your Kubernetes cluster. The deployment might take a while.

5.  **Get the initial password**

If you didn't set a custom password, you can get the initial root password with the following command after the installation is complete:

```bash
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode ; echo
```

6.  **Access GitLab**

Once the deployment is finished and the DNS records are pointing to your ingress controller, you can access GitLab at the domain you configured. Log in with the username `root` and your custom password, or the randomly generated one.

## Ingress Configuration

This installation assumes you have an Ingress controller running in your cluster. If you don't have one, you'll need to set one up.

An example Ingress configuration is provided in `ingress-gitlab-template.yml`. You will need to customize it for your environment, especially the `host` and `tls` sections.

## Uninstallation

To uninstall GitLab, run the following command:

```bash
helm uninstall gitlab -n gitlab
```

## Upgrading GitLab and Applying Changes

To apply changes from `gitlab-template.yml` (like the addition of the PostgreSQL `initContainer`), use the `helm upgrade` command. This ensures that your GitLab deployment is updated with the latest configurations without requiring a full re-installation.

The `initContainer` was added to the PostgreSQL configuration to automatically remove the stale `postmaster.pid` file that can prevent PostgreSQL from starting after an unexpected shutdown.

To upgrade your GitLab instance, run the following command:

```bash
helm upgrade gitlab gitlab/gitlab \
    --namespace gitlab \
    --values gitlab-template.yml
```
