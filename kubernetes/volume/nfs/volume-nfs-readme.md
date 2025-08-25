# NFS Server Setup for Kubernetes

This guide outlines how to set up an NFS server to provide persistent storage for a Kubernetes cluster. The process is automated using an Ansible playbook.

---
## 1. Automated NFS Server Configuration

The provided Ansible playbook, `nfs-server.yml`, automates the installation and configuration of the NFS server on the designated `nfs-server` host (as defined in `config/inventory.ini`).

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/volume/nfs/nfs-server.yml --ask-become-pass
```

---
## 2. Worker Node Preparation

To allow Kubernetes worker nodes to connect to the NFS server, you need to install the `nfs-common` package on each of them. This can be done using the provided Ansible playbook.

### 2.1. Run the Ansible Playbook

From your Ansible control node, run the following command. This playbook automates the installation of the required NFS client packages on all worker nodes defined in your inventory.

```bash
# This command targets the hosts in the 'workers' group of your inventory file.
# It is a critical prerequisite for the NFS CSI driver to function correctly.
ansible-playbook -i ./config/inventory.ini ./kubernetes/volume/nfs/nfs-prereq.yml --ask-become-pass
```

This playbook will typically perform the following actions:
- Update the package cache (`apt-get update`, `dnf check-update`, etc.).
- Install the `nfs-common` or `nfs-utils` package.

---
## 3. Verification (Optional)

To verify that the NFS share is accessible from a worker node, you can manually mount it.

### 3.1. Manually Mount the Share

Log in to a worker node and run the following commands. Replace `[NFS_SERVER_IP]` with the IP address of your NFS server (e.g., the IP of `nas-01` from your inventory) and `/mnt/nfs-share` with the path you configured.

```bash
sudo mkdir /mnt/nfs-test
sudo mount -t nfs [NFS_SERVER_IP]:/mnt/nfs-share /mnt/nfs-test
```

### 3.2. Test the Mount

Create a test file in the mounted directory:

```bash
echo "NFS test successful" > /mnt/nfs-test/test.txt
```

You should be able to see this file from the NFS server in the `/mnt/nfs-share` directory.

### 3.3. Unmount the Share

Once you have verified the connection, unmount the test directory:

```bash
sudo umount /mnt/nfs-test
```

## 4. Permanent Mount (Optional)

To make the mount permanent on a worker node, you can add it to the `/etc/fstab` file.

### 4.1. Edit `/etc/fstab`

Add the following line to the `/etc/fstab` file on the worker node. Replace `[NFS_SERVER_IP]` and `/mnt/nfs-share` with your specific values.

```
[NFS_SERVER_IP]:/mnt/nfs-share /mnt/nfs-mountpoint nfs defaults 0 0
```

## Next Steps: NFS CSI Driver and StorageClass Setup

After successfully preparing your worker nodes by running the playbook above, the next step is to deploy the NFS CSI (Container Storage Interface) driver to your Kubernetes cluster.

This driver will act as the bridge between Kubernetes and your NFS server, allowing you to dynamically provision `PersistentVolumes`.

Once the driver is installed, you will need to create a `StorageClass` that references it. This `StorageClass` will then be used to automatically provision storage for your applications via `PersistentVolumeClaims`.

---
## CAUTION: Cleaning NFS Volumes

A playbook is available to clean up the NFS volumes. This is a destructive operation and should be used with extreme care.

**Playbook:** `clean-nfs-volume.yml`

This playbook will permanently delete all data within the `/mnt/server` directory on the specified NFS host.

**Usage:**

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/volume/nfs/clean-nfs-volume.yml --ask-become-pass
```

The playbook will prompt for the following information:
- **NFS server host:** The target host from your inventory (e.g., `nas-003`).
- **Confirmation:** You must type `yes` to proceed with the deletion.

**WARNING:** This action is irreversible. Make sure you have selected the correct host and that you have backed up any important data before running this playbook.