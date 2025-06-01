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

### Step 1: Prepare the System for Kubernetes

This step may include tasks such as installing dependencies required for the container runtime.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s_prep.yml --ask-become-pass
```

### Step 2: Install Container Runtime ( Containerd )

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/containerd.yml --ask-become-pass
```

### Step 3: Install kubectl, kubeadm, and kubelet

These tools are essential for interacting with the Kubernetes cluster.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/kubectl.yml --ask-become-pass
```

### Step 4: Configure loadbalancer 

Please read and Step `README.md` for loadbalancer section, this file in `./loadbalancer`

---
## Initialize and configure Master Nodes
