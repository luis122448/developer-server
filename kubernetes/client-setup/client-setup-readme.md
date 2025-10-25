# Setting Up Remote `kubectl` Access

This document provides instructions on how to set up `kubectl` on a remote machine to interact with the Kubernetes cluster.

## Installation

Ansible playbooks are provided to automate the installation of the `kubectl` command-line tool on different operating systems.

- **Debian/Ubuntu:** `ansible-playbook -i ./config/inventory.ini ./kubernetes/client-setup/install-kubectl-debian.yml --ask-become-pass`
- **Arch Linux:** `ansible-playbook -i ./config/inventory.ini ./kubernetes/client-setup/install-kubectl-arch.yml --ask-become-pass`
- **Oracle Linux:** `ansible-playbook -i ./config/inventory.ini ./kubernetes/client-setup/install-kubectl-oracle.yml --ask-become-pass`

Choose the playbook that matches your client's operating system. These playbooks are designed to be run locally on the client machine.

## Configuration

After installing `kubectl`, you need to fetch the cluster configuration file from one of the master nodes.

### 1. Fetch Cluster Configuration

From your local machine, use `scp` to copy the `admin.conf` file from a master node. This file contains the credentials to access the cluster.

```bash
# Replace <user> and <your-master-node-ip> with your actual data
scp <user>@<your-master-node-ip>:/etc/kubernetes/admin.conf ~/
```

### 2. Configure Local Environment

`kubectl` expects the configuration file to be at `~/.kube/config`.

```bash
# Create the .kube directory if it doesn't exist
mkdir -p ~/.kube

# Move the downloaded config file to the correct location
mv ~/admin.conf ~/.kube/config

# Set the correct ownership and permissions
chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

### 3. Verify the Connection

Run a `kubectl` command to verify that you can connect to your cluster.

```bash
kubectl get nodes
```

You should see a list of the nodes in your cluster. If you get a permission error, double-check the ownership of the `~/.kube/config` file.
