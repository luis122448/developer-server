# NFS CSI Driver and StorageClass Setup

This guide provides instructions for installing the NFS CSI (Container Storage Interface) driver on a Kubernetes cluster and configuring a StorageClass to dynamically provision PersistentVolumes (PVs) using an NFS share.

---
## 1. Install NFS CSI Driver

The recommended method for installing the NFS CSI driver is by using Helm. This simplifies the installation and management of the driver.

### 1.1. Add Helm Repository

First, add the official NFS CSI driver Helm repository:

```bash
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
```

### 1.2. Update Helm Repositories

Next, update your local Helm repositories to fetch the latest chart information:

```bash
helm repo update
```

### 1.3. Install the Driver

Install the NFS CSI driver into the `kube-system` namespace using the following command:

```bash
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --version v4.11.0
```

**Note:** It is recommended to check for the latest version of the Helm chart before installation.

---
## 2. Create the StorageClass

Once the NFS CSI driver is installed, you need to create a StorageClass that allows Kubernetes to provision volumes on the NFS share. The `nas-001.yaml` file in this directory provides an example configuration.

### 2.1. Apply the StorageClass Manifest

To create the StorageClass, apply the `nas-001.yaml` manifest:

```bash
kubectl apply -f kubernetes/volume/class/nas-001.yaml
```

This will create a StorageClass named `nas-001` that is configured to use the NFS server at `192.168.100.171` and the `/mnt/server` share.

---
## 3. Dynamic Provisioning

With the StorageClass created, you can now create PersistentVolumeClaims (PVCs) that will dynamically provision PVs on the NFS share.

### 3.1. Example PVC

Here is an example of a PVC that uses the `nas-001` StorageClass:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-nfs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nas-001
  resources:
    requests:
      storage: 1Gi
```

When you apply this manifest, the NFS CSI driver will automatically create a corresponding PV on the `nas-001` NFS server.
