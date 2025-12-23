# External Services Integration

This directory contains configurations to expose services running **outside** the Kubernetes cluster (e.g., in Docker containers on the local network) via the cluster's Ingress Controller.

## General Objective

Redirect secure external traffic to insecure local IPs:
`Internet (HTTPS) -> Ingress (domain.bbg.pe) -> Service (Cluster) -> Docker Host (192.168.100.161:PORT)`

## Projects

### 1. Nextcloud (NAS)
*   **Path**: `nas-nextcloud/`
*   **Domain**: `nas.bbg.pe`
*   **Target**: `192.168.100.161:8002`
*   **Features**: Includes configuration for large file uploads (`proxy-body-size: 10g`).

### 2. Navidrome (Music)
*   **Path**: `navidrome/`
*   **Domain**: `music.bbg.pe`
*   **Target**: `192.168.100.161:8003`

## Deployment

To deploy a specific service:

```bash
# Deploy Nextcloud
kubectl apply -f kubernetes/external/nas-nextcloud/

# Deploy Navidrome
kubectl apply -f kubernetes/external/navidrome/
```

## Verification

Check if the endpoints are correctly mapped to the external IP:

```bash
kubectl get endpoints nextcloud-external-svc navidrome-external-svc
```

Check the status of the Ingresses:

```bash
kubectl get ingress nextcloud-external-ingress navidrome-external-ingress
```

## Requirements

*   **Network**: The Kubernetes nodes must have network visibility to the external IP (`192.168.100.161`).
*   **Cert Manager**: A `ClusterIssuer` named `letsencrypt-prod` is required for automatic SSL generation.
