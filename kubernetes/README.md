# Kubernetes Installation on Raspberry Pi and N100 Intel

This document outlines the process for setting up and installing a Kubernetes cluster that includes nodes based on Raspberry Pi and nodes with Intel N100 processors. Ansible is used to automate most of the configuration and installation tasks.

---
## Prerequisites

Before you begin, ensure you have the following:

* **SSH access** to all servers (Raspberry Pi and N100) with `sudo` privileges.
* **Ansible** installed on your management machine.
* An **Ansible inventory** (`inventory.ini`) configured with the IP addresses or hostnames of your servers. The inventory should be organized so you can target different node types if necessary.
* **Basic understanding** of Kubernetes and Ansible.

---
## Ansible Playbook Structure

It is assumed that you have a directory structure similar to the following:

    ├── config/
    │   └── inventory.ini
    └── kubernetes/
        ├── configure_kernel.yml
        ├── containerd.yml
        ├── disable_swap.yml
        ├── install_docker.yml
        ├── k8s_prep.yml
        ├── kubectl.yml
        ├── restart.yml
    └── ... other ...

----
## Installation Steps

The following details the steps for installing Kubernetes.

### 1. Disable Swap

Swap can interfere with Kubernetes performance. It is recommended to disable it on all nodes.

```bash
ansible-playbook -i ./kubernetes/inventory.ini ./kubernetes/disable_swap.yml --ask-become-pass
```

### 2. Configure Kernel

Kernel configurations are adjusted to enable the necessary components for Kubernetes.

```bash
ansible-playbook -i ./kubernetes/inventory.ini ./kubernetes/configure_kernel.yml --ask-become-pass
```
### 3. Prepare the System for Kubernetes

This step may include tasks such as installing dependencies required for the container runtime.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s_prep.yml --ask-become-pass
```

### 4. Install Container Runtime (Docker or Containerd)

Choose a container runtime for Kubernetes. Examples for Docker and Containerd are shown here.

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/install_docker.yml --ask-become-pass
```

or 

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/containerd.yml --ask-become-pass
```

### 5. Install kubectl, kubeadm, and kubelet

These tools are essential for interacting with the Kubernetes cluster.

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/kubectl.yml --ask-become-pass
```

### 6. Reboot Nodes

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/restart.yml --ask-become-pass
```

### 7. Configure Load Balancer (Optional)

If you plan to have multiple master nodes for high availability, you will need to configure a load balancer in front of them. The specific configuration will depend on your environment (e.g., MetalLB for bare-metal environments or a load balancer provided by your cloud provider).

Note: The control-plane-endpoint used in the next step (kubeadm init) should be the IP address or domain name of the load balancer.

### 8. Initialize the First Master Node

Connect to the node you will designate as the first master node (n100-001 in your example) and run the following command:

```bash
sudo kubeadm init \
  --control-plane-endpoint "<LOAD_BALANCER_IP>:6443" \
  --upload-certs \
  --pod-network-cidr=10.244.0.0/16
```

Important:

Replace <LOAD_BALANCER_IP> with the IP address or domain name of your load balancer. If you are not using a load balancer, use the IP address of this first master node.
The --pod-network-cidr argument defines the IP address range that will be assigned to pods. 10.244.0.0/16 is a commonly used range for Flannel.
Upon completion of this command, you will receive a kubeadm join command to join other master and worker nodes to the cluster. Keep this information safe.

### 9. Initialize and Join the Second Master Node

Connect to the second master node (n100-002 in your example) and run the kubeadm join command you obtained in the previous step. It should have the following structure:

```bash
kubeadm join <FIRST_MASTER_IP>:6443 \
  --token <span class="math-inline">\{TOKEN\} \\
\-\-discovery\-token\-ca\-cert\-hash sha256\:</span>{HASH} \
  --control-plane \
  --certificate-key ${CERT_KEY}
```

Note: Make sure to replace <FIRST_MASTER_IP>, ${TOKEN}, ${HASH}, and ${CERT_KEY} with the values provided by the kubeadm init command executed on the first master node. The --control-plane flag indicates that this node will also be a master node.

### 10. Install the CNI (Network Plugin)

Kubernetes requires a CNI (Container Network Interface) to enable communication between pods. Flannel is a popular option. Execute the following command on the master node:

```bash
kubectl apply -f [https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml](https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml)
```

Important: Ensure that the pod-network-cidr defined in the kubeadm init matches the configuration of the CNI you choose (in this case, Flannel uses 10.244.0.0/16 by default).

### 11. Join Worker Nodes

Connect to each worker node (both Raspberry Pi and N100 that are not masters) and run the kubeadm join command you obtained in step 8. The structure will be similar to:

```bash
kubeadm join <FIRST_MASTER_IP>:6443 \
  --token <span class="math-inline">\{TOKEN\} \\
\-\-discovery\-token\-ca\-cert\-hash sha256\:</span>{HASH}
```

Note: Make sure to replace <FIRST_MASTER_IP>, ${TOKEN}, and ${HASH} with the values provided by the kubeadm init command on the first master node.

After executing the kubeadm join command on each worker node, you can enable and verify the status of the kubelet:

```bash
systemctl enable --now kubelet
systemctl status kubelet
```

### 12. Final Validation

From the master node, verify that all nodes have joined the cluster correctly and that the system pods are running:

```bash
kubectl get nodes
```

You should see all your nodes in a Ready state.

```bash
kubectl get pods -n kube-system
```

Verify that essential system pods, such as the CNI (e.g., Flannel pods) and the DNS (coredns), are in a Running state.