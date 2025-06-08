# Kubernetes Installation on Raspberry Pi and N100 Intel

This document outlines the process for setting up and installing a Kubernetes cluster that includes nodes based on Raspberry Pi and nodes with Intel N100 processors. Ansible is used to automate most of the configuration and installation tasks.

---
## Prerequisites

Before you begin, ensure the following requirements are met:

* **SSH Access:** You must have SSH access to all target nodes with a user that has `sudo` privileges.
* **Ansible Controller:** Ansible must be installed on your management machine (e.g., `dev-003`).
* **Ansible Inventory:** A correctly configured inventory file (`config/inventory.ini`) is required. It should list all your master and worker nodes, organized into groups.
    *Example:*
    ```ini
    [masters]
    n100-001 ansible_host=192.168.100.181
    n100-002 ansible_host=192.168.100.182
    n100-003 ansible_host=192.168.100.183

    [workers]
    raspberry-001 ansible_host=192.168.100.101
    raspberry-002 ansible_host=192.168.100.102
    # ... and so on
    ```
* **Network Connectivity:** All nodes must be able to communicate with each other over the network.

---
## Ansible Playbook Structure

It is assumed that you have a directory structure similar to the following:

.
├── config/
│   └── inventory.ini
└── kubernetes/
    ├── add-hosts.yml
    ├── containerd.yml
    ├── k8s.yml
    ├── k8s-tools.yml
    ├── k8s-cluster-prep.yml
    └── reset-cluster.yml

---
## 3. Installation Workflow

The installation is divided into logical phases. Execute the commands from your Ansible controller machine.

### Phase 1: Node Preparation (All Nodes)

These playbooks prepare every node in the cluster (both masters and workers) by installing necessary dependencies, setting up kernel parameters, and installing the container runtime.

```bash
# Prepare system (disable swap, configure kernel modules, etc.)
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s-cluster-prep.yml --ask-become-pass

# Install the Containerd container runtime
ansible-playbook -i ./config/inventory.ini ./kubernetes/containerd.yml --ask-become-pass

# Install Kubernetes binaries (kubeadm, kubelet, kubectl)
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s.yml --ask-become-pass

# Install Management Tools (Heml & Bash Completion)
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s-tools.yml --ask-become-pass
```

### Phase 2: High Availability (HA) Load Balancer Setup

For a multi-master setup, a load balancer is required to provide a single, stable endpoint to the Kubernetes API Server.

Note: Please refer to the instructions in `./loadbalancer/README.md` to configure your load balancer. It should be configured to balance TCP traffic on port `6443` across all your master nodes (e.g., `192.168.100.181`, `182`, `183`). Assume the load balancer's virtual IP is `192.168.100.171`.

### Phase 3: Initialize the Control Plane (First Master Node)

Run this command only on your first master node (e.g., `n100-001`) to initialize the cluster.

```bash
# SSH into your first master node before running this command
sudo kubeadm init \
  --control-plane-endpoint="192.168.100.171:6443" \
  --upload-certs \
  --pod-network-cidr="10.244.0.0/16" \
  --cri-socket="unix:///var/run/containerd/containerd.sock" \
  --kubernetes-version="v1.32.3"
```

**IMPORTANT**: The output of this command is critical. It contains the kubeadm join commands with the necessary tokens and hashes to add other nodes. Save this output securely!

### Phase 4: Configure kubectl Access (Management Machine)

To interact with your new cluster, configure kubectl on your management machine.

```bash
# These commands should be run on the machine where you will manage the cluster from (e.g., dev-003 or the first master)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown <span class="math-inline">\(id \-u\)\:</span>(id -g) $HOME/.kube/config
```

After this, you can verify cluster access by running:

```bash
kubectl get nodes
```

The first master node should appear with a `NotReady` status until a CNI is installed.

### Phase 5: Install the CNI (Pod Network)

```bash
# Add the Cilium Helm repository
helm repo add cilium [https://helm.cilium.io/](https://helm.cilium.io/)
helm repo update

# Generate the manifest and apply it (tee is used to handle sudo permissions for file creation)
helm template cilium cilium/cilium --version 1.16.1 \
--namespace kube-system | sudo tee cilium.yaml > /dev/null

kubectl apply -f cilium.yaml

# Verify the Cilium pods are starting up
kubectl get pods -n kube-system -l k8s-app=cilium
```

### Phase 6: Join Remaining Nodes to the Cluster

Now, use the kubeadm join commands you saved from Phase 3 to add your other master and worker nodes.

To join other Control-Plane nodes:
SSH into each additional master node (e.g., `n100-002`, `n100-003`) and run the join command for control planes as root.

```bash
# Example command (use the one from YOUR kubeadm init output)
sudo kubeadm join 192.168.100.171:6443 --token <your_token> \
        --discovery-token-ca-cert-hash sha256:<your_hash> \
        --control-plane --certificate-key <your_cert_key>
```

To join Worker nodes:
SSH into each worker node (e.g., `raspberry-001`, `raspberry-002`, etc.) and run the join command for workers as root.

```bash
# Example command (use the one from YOUR kubeadm init output)
sudo kubeadm join 192.168.100.171:6443 --token <your_token> \
        --discovery-token-ca-cert-hash sha256:<your_hash>
```

---
## Post-Installation Tasks

### Allow Pods on Master Nodes (Optional)

By default, master nodes are "tainted" to prevent user workloads from running on them. If you want to use your masters to run pods, you must remove this taint.

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Actions for add pods on master node

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/add-hosts.yml --ask-become-pass
```

---
## Troubleshooting: Full Cluster Reset

If you need to start over, this playbook will reset all nodes to clean state by running `kubeadm reset` and wiping configuration directories.

**WARNING**: This is a destructive action and will permanently delete your cluster configuration on the nodes.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/reset-cluster.yml --ask-become-pass
```
