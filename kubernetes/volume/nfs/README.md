# NFS Server Setup for Kubernetes

This documentation outlines the steps to configure an NFS server and prepare Kubernetes worker nodes to use it for persistent storage.

---
## 1. NFS Server Configuration (on nas-001)

This section details the necessary steps to install and configure an NFS server on the `nas-001` host. These commands should be executed directly on the `nas-001` server.

### 1.1. Install NFS Server

First, install the necessary packages for the NFS server:

```bash
sudo apt update
sudo apt install nfs-kernel-server
```

### 1.2. Create the Export Directory

Create the directory that will be shared via NFS. In this case, we'll use `/mnt/server`.

```bash
sudo mkdir -p /mnt/server
```

### 1.3. Configure NFS Exports

Next, configure the NFS server to export the `/mnt/server` directory.

```bash
sudo nano /etc/exports
```

Add the following line to the `/etc/exports` file:

```bash
/mnt/server *(rw,sync,no_subtree_check)
```

This configuration allows any client (`*`) to mount the directory with read-write permissions.

### 1.4. Apply Export Configuration

After modifying the `/etc/exports` file, apply the changes:

```bash
sudo exportfs -a
```

### 1.5. Restart NFS Service

Finally, restart the NFS kernel server to apply all changes:

```bash
sudo systemctl restart nfs-kernel-server
```

---
## 2. Worker Node Preparation

To allow Kubernetes worker nodes to connect to the NFS server, you need to install the `nfs-common` package on each of them. This can be done using the provided Ansible playbook.

### 2.1. Run the Ansible Playbook

From your Ansible control node, run the following command. This playbook automates the installation of the required NFS client packages on all worker nodes defined in your inventory.

```bash
# This command targets the hosts in the 'workers' group of your inventory file.
# It is a critical prerequisite for the NFS CSI driver to function correctly.
ansible-playbook -i ./config/inventory.ini ./kubernetes/nfs/nfs-prereq.yml --ask-become-pass
```

This playbook will typically perform the following actions:
- Update the package cache (`apt-get update`, `dnf check-update`, etc.).
- Install the `nfs-common` or `nfs-utils` package.

---
## 3. Verification (Optional)

To verify that the NFS share is accessible from a worker node, you can manually mount it.

### 3.1. Manually Mount the Share

Log in to a worker node and run the following commands:

```bash
sudo mkdir /mnt/nfs-test
sudo mount -t nfs 192.168.100.171:/mnt/server /mnt/nfs-test
```

Replace `192.168.100.171` with the actual IP address of your `nas-001` server.

### 3.2. Test the Mount

Create a test file in the mounted directory:

```bash
echo "NFS test successful" > /mnt/nfs-test/test.txt
```

You should be able to see this file from the `nas-001` server in the `/mnt/server` directory.

### 3.3. Unmount the Share

Once you have verified the connection, unmount the test directory:

```bash
sudo umount /mnt/nfs-test
```

## 4. Permanent Mount (Optional)

To make the mount permanent on a worker node, you can add it to the `/etc/fstab` file.

### 4.1. Edit `/etc/fstab`

Add the following line to the `/etc/fstab` file on the worker node:

```
192.168.100.171:/mnt/server /mnt/nfs-mountpoint nfs defaults 0 0
```

Replace `192.168.100.171` with the IP of your NFS server and `/mnt/nfs-mountpoint` with the desired mount point.

## Next Steps: NFS CSI Driver and StorageClass Setup

After successfully preparing your worker nodes by running the playbook above, the next step is to deploy the NFS CSI (Container Storage Interface) driver to your Kubernetes cluster.

This driver will act as the bridge between Kubernetes and your NFS server, allowing you to dynamically provision `PersistentVolumes`.

Once the driver is installed, you will need to create a `StorageClass` that references it. This `StorageClass` will then be used to automatically provision storage for your applications via `PersistentVolumeClaims`.
