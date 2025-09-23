# Vault on Kubernetes (Helm) - Quick Guide

This guide summarizes the installation, configuration, and backup/restore process for HashiCorp Vault on Kubernetes using Helm and Raft storage.

---

## 1. Installation

```bash
# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com

# Install Vault in a dedicated namespace
kubectl apply -f k8s/vault/namespace.yaml
```

## 2. Basic Configuration (values.yaml example)

```yaml
server:
  ha:
    enabled: true
    raft:
      enabled: true

  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: nas-003

  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    hosts:
      - host: vault.lcalvo.com
        paths:
          - /
    tls:
      - secretName: vault-lcalvo-com-tls
        hosts:
          - vault.lcalvo.com

ui:
  enabled: true
```

Install and configure Vault with Helm:

```bash
helm install vault hashicorp/vault -n vault-production -f default-values.yaml
```

4. Verify pods:

```bash
kubectl get pods -n vault-production
```

Expected output:

```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          5m
vault-1                                 0/1     Running   0          5m
vault-2                                 0/1     Running   0          5m
vault-agent-injector-xxxxxxx            1/1     Running   0          5m
```

**Note:** Pods will be in `0/1` state until unsealed.

---

## 3. Initialization & Unseal

1. Enter the main Vault pod:

```bash
kubectl exec -it vault-0 -n vault-production -- sh
export VAULT_ADDR=http://127.0.0.1:8200
```

2. Initialize Vault (only once):

```bash
vault operator init
```

This will generate **5 unseal keys** and a **root token**. Store the keys securely.

**IMPORTANT:** The root token is for emergency use only. Create admin tokens/policies for daily operations.

3. Unseal Vault using 3 of the 5 keys:

```bash
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### 3.1. Join Raft nodes

Run from your terminal (not inside the pod):

```bash
kubectl exec -it vault-1 -n vault-production -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it vault-2 -n vault-production -- vault operator raft join http://vault-0.vault-internal:8200
```

### 3.2. Unseal additional nodes

```bash
kubectl exec -it vault-1 -n vault-production -- vault operator unseal <key1>
kubectl exec -it vault-1 -n vault-production -- vault operator unseal <key2>
kubectl exec -it vault-1 -n vault-production -- vault operator unseal <key3>

kubectl exec -it vault-2 -n vault-production -- vault operator unseal <key1>
kubectl exec -it vault-2 -n vault-production -- vault operator unseal <key2>
kubectl exec -it vault-2 -n vault-production -- vault operator unseal <key3>
```

Verify that all pods are ready:

```bash
kubectl get pods -n vault-production
```

Expected output:

```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          10m
vault-1                                 1/1     Running   0          10m
vault-2                                 1/1     Running   0          10m
vault-agent-injector-68d5887f75-g87qp   1/1     Running   0          10m
```

---

## 4. Daily Operations

* Create admin tokens/policies instead of using Root.
* Use `vault status` to check seal and HA status.

---

## 5. Backup & Restore (Raft Storage)

### Backup

```bash
export VAULT_ADDR=https://vault.luis122448.com
vault operator raft snapshot save backup.snap
```

Store `backup.snap` securely.

### Restore

```bash
vault operator raft snapshot restore backup.snap
```

This will restore all secrets, policies, and users.

### Optional PVC Snapshots

If your StorageClass supports snapshots, you can backup the persistent volumes directly.

---

## 6. Recovery After Pod Restart

1. Pods start sealed by default.
2. Use **3 of 5 Unseal Keys** to unseal each pod.
3. Cluster becomes accessible, all secrets intact.

> Tip: Consider **Auto-unseal** with KMS/HSM for fully automated startup.

---

## 7. Security Notes

* Root Token: keep offline, emergency use only.
* Unseal Keys: distribute securely among trusted admins.
* Do not store unseal keys and root token in the same location.

---

## References

* [Vault Helm Chart Docs](https://github.com/hashicorp/vault-helm)
* [Vault Official Docs](https://developer.hashicorp.com/vault/docs)
