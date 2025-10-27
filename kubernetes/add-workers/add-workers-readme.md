# Adding a New Worker Node to the Cluster

This guide outlines the procedure for adding new worker nodes, such as your new Raspberry Pis, to the existing Kubernetes cluster using the provided Ansible playbooks.

### Step 1: Update Ansible Inventory

First, add your new worker nodes to the Ansible inventory file located at `config/inventory.ini`. Add their hostnames and IP addresses under the `[workers]` group.

*Example:*
```ini
[workers]
raspberry-001 ansible_host=192.168.100.101
raspberry-002 ansible_host=192.168.100.102
# ... existing workers
raspberry-007 ansible_host=192.168.100.107 # New Node 1
raspberry-008 ansible_host=192.168.100.108 # New Node 2
```

### Step 2: Update Host Resolution

To ensure all nodes in the cluster can resolve each other by hostname, you must update the `hosts.j2` template and apply it.

1.  **Edit the template:** Open the `kubernetes/hosts.j2` file and add the new nodes' IP addresses and hostnames.

```j2
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback

# Existing Cluster Nodes
192.168.100.181  n100-001
192.168.100.182  n100-002
# ... other nodes

# New Worker Nodes
192.168.100.107  raspberry-007
192.168.100.108  raspberry-008
```

2.  **Apply the changes:** Run the `add-hosts.yml` playbook to distribute the updated `/etc/hosts` file to all nodes in the cluster.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/add-workers/add-hosts.yml --ask-become-pass
```

### Step 3: Prepare the New Nodes

Run the node preparation playbooks to install all necessary dependencies, configure the system, and install Kubernetes components. Use the `--limit` flag to target only your new nodes.

**Important**: Replace `raspberry-007,raspberry-008` with the actual hostnames you defined in your inventory file.

```bash
# Run all preparation playbooks, targeting only the new nodes
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s-cluster-prep.yml --limit "raspberry-007,raspberry-008" --ask-become-pass
ansible-playbook -i ./config/inventory.ini ./kubernetes/containerd.yml --limit "raspberry-007,raspberry-008" --ask-become-pass
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s.yml --limit "raspberry-007,raspberry-008" --ask-become-pass
ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s-tools.yml --limit "raspberry-007,raspberry-008" --ask-become-pass
```

### Step 3: Generate a New Join Token

SSH into any of your master nodes (e.g., `n100-001`) and generate a new worker join command. This will provide a fresh token and the required discovery hash.

```bash
# On a master node
sudo kubeadm token create --print-join-command
```

This will output a command similar to this. Copy it, as you will need the token and hash for the next step.
`kubeadm join 192.168.100.230:6443 --token <your_new_token> --discovery-token-ca-cert-hash sha256:<your_new_hash>`

### Step 4: Join the Nodes to the Cluster

Use the `join-workers.yml` playbook with the token and hash you just generated. Again, use `--limit` to target only the new nodes.

```bash
# Replace with your new token and hash
ansible-playbook -i ./config/inventory.ini ./kubernetes/add-workers/join-workers.yml \
--extra-vars "kubeadm_apiserver_endpoint=192.168.100.230:6443 kubeadm_token=<your_new_token> discovery_token_ca_cert_hash=sha256:<your_new_hash>" \
--limit "raspberry-007,raspberry-008" \
--ask-become-pass
```

### Step 5: Verify the New Nodes

After the playbook finishes, check the status of your nodes from your management machine. The new nodes should appear in the list. It may take a minute or two for their status to change from `NotReady` to `Ready` as the CNI pods are deployed on them.

```bash
kubectl get nodes -o wide
```

Your new Raspberry Pi nodes should now be fully operational members of your Kubernetes cluster.
