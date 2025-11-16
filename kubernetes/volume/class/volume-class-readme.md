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

```bash
kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/instance=csi-driver-nfs" --watch
```

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

---
# Default StorageClass

In Kubernetes, a `StorageClass` provides a way for administrators to describe the "classes" of storage they offer. Different classes might map to quality-of-service levels, backup policies, or to arbitrary policies determined by the cluster administrators.

## What is the Default StorageClass?

A Kubernetes cluster can be configured with a **default `StorageClass`**. This default class is used to dynamically provision storage for `PersistentVolumeClaim`s (PVCs) that **do not explicitly specify a `storageClassName`**.

This is a powerful feature, but also one to be aware of, as it can be the source of unexpected behavior if not managed correctly. It can be particularly useful as a workaround for Helm charts or operators that fail to correctly set a `storageClassName` on the PVCs they create.

## How to Find the Default StorageClass

You can list all `StorageClass`es in your cluster and identify the default one by running the following command:

```bash
kubectl get storageclass
```

The output will show a list of available `StorageClass`es. The one marked with `(default)` is the current default for the cluster.

**Example Output:**

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nas-002              nfs.storage.com/nfs        Delete          Immediate           false                  90d
nas-003              nfs.storage.com/nfs        Delete          Immediate           false                  90d
local-storage        kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  90d
standard (default)   kubernetes.io/gce-pd       Delete          Immediate           true                   120d
```

In this example, `standard` is the default `StorageClass`.

## How to Change the Default StorageClass

Changing the default `StorageClass` is a two-step process if a default already exists. You must first unset the current default and then set the new one. A cluster can only have one default `StorageClass`.

### 1. Unset the Current Default

If a `StorageClass` is already marked as default, you must first remove that designation. Replace `<current-default-sc-name>` with the actual name of the current default `StorageClass`.

```bash
kubectl patch storageclass <current-default-sc-name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### 2. Set the New Default

Once no other class is marked as default, you can set your desired `StorageClass` as the new default. Replace `<your-new-default-sc-name>` with the name of the class you want to make default (e.g., `nas-003`).

```bash
kubectl patch storageclass <your-new-default-sc-name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

After running these commands, you can verify the change by running `kubectl get storageclass` again.