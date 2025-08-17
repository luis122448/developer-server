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
## Installation Workflow

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

Note: Please refer to the instructions in '../loadbalancer/loadbalancer-readme.md' to configure your load balancer. It should be configured to balance TCP traffic on port `6443` across all your master nodes (e.g., `192.168.100.181`, `182`, `183`). Assume the load balancer's virtual IP is `192.168.100.230`.

### Phase 3: Initialize the Control Plane (First Master Node)

Run this command only on your first master node (e.g., `n100-001`) to initialize the cluster.

```bash
sudo kubeadm init \
  --control-plane-endpoint="192.168.100.230:6443" \
  --upload-certs \
  --pod-network-cidr="10.244.0.0/16" \
  --cri-socket="unix:///var/run/containerd/containerd.sock" \
  --kubernetes-version="v1.32.3"
```

**IMPORTANT**: The output of this command is critical. It contains the kubeadm join commands with the necessary tokens and hashes to add other nodes. Save this output securely!

### Phase 4: Configure kubectl Access (Management Machine)

To interact with your new cluster, configure kubectl on your management machine.

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

After this, you can verify cluster access by running:

```bash
kubectl get nodes
```

The first master node `n100-001` should appear with a `NotReady` status until a CNI is installed.

### Phase 5: Join Remaining Master Nodes to the Cluster

Now, use the kubeadm join commands you saved from Phase 3 to add your other master and worker nodes.

To join other Control-Plane nodes:
SSH into each additional master node (e.g., `n100-002`, `n100-003`) and run the join command for control planes as root.

```bash
# Example command (use the one from YOUR kubeadm init output)
sudo kubeadm join 192.168.100.230:6443 --token <your_token> \
        --discovery-token-ca-cert-hash sha256:<your_hash> \
        --control-plane --certificate-key <your_cert_key>
```

Can recreate the command with

```bash
kubeadm token create --print-join-command
kubeadm init phase upload-certs --upload-certs

kubeadm join <master_ip>:<master_port> --token <new_token> --discovery-token-ca-cert-hash sha256:<new_hash> --control-plane --certificate-key <new_certificate_key>
```

### Phase 6: Install the CNI (Pod Network)

Before installing Cilium, ensure that the required ports are open between all cluster nodes to allow for proper communication.

**Firewall Prerequisites for Cilium**
You must allow traffic on the following ports between all nodes for Cilium to function correctly.

| Port	| Protocol |	Purpose |
| ----	| -------- |	------- |
| 4240	| TCP |	Health Checking: Cilium agent health and status probes. |
| 4244	| TCP |	Hubble: Required for Hubble observability and metrics. |
| 4245	| TCP |	Hubble Relay: Service for Hubble UI and CLI to gather data. |
| 8472	| UDP |	VXLAN Overlay: Default port for pod-to-pod network traffic in VXLAN mode. |

**Note**: If you were using Cilium with WireGuard encryption, you would also need to open `UDP` port `51871`.

Now, proceed with the installation of Cilium using the specified Helm configuration.

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium --version 1.16.1 \
   --namespace kube-system \
   --set kubeProxyReplacement=false \
   --set l2announcements.enabled=true \
   --set externalIPs.enabled=true \
   --set bpf.masquerade=true \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true \
   --set nodePort.enabled=true
```

Verify that the Cilium pods are starting up correctly. It may take a few minutes for all containers to be in the `Running` state.

```bash
kubectl get pods -n kube-system -l k8s-app=cilium
```

After all Cilium pods are running, you can verify that all nodes are in a `Ready` state, which confirms that the CNI is operational.

```bash
kubectl get nodes
```

### Phase 7: Join Remaining Worker Nodes to the Cluster

To integrate your worker nodes into the Kubernetes cluster, follow these steps:

SSH into each worker node (e.g., `raspberry-001`, `raspberry-002`, etc.) and run the join command for workers as root.

```bash
kubeadm join 192.168.100.230:6443 --token <your_token> --discovery-token-ca-cert-hash sha256:<your_hash>
```

Note: If you need to regenerate the join command, you can do so on your control plane node by running:

```bash
kubeadm token create --print-join-command
```

Alternatively, for an automated approach, you can use the provided Ansible playbook:

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/join-workers.yml --extra-vars "kubeadm_apiserver_endpoint=192.168.100.230:6443 kubeadm_token=<your_token> discovery_token_ca_cert_hash=<your_hash>" --ask-become-pass
```

After all worker nodes have successfully joined the cluster, verify their status by executing the following command on your control plane node:

```bash
kubectl get nodes
```

---
## Post-Installation Tasks

### Allow Pods on Master Nodes (Optional)

By default, master nodes are "tainted" to prevent user workloads from running on them. If you want to use your masters to run pods, you must remove this taint.

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Persistent Storage with NFS

For information on how to configure PersistentVolumes (PVs), PersistentVolumeClaims (PVCs), and StorageClasses using NFS, please refer to the detailed documentation in the `./nfs` directory.

- **[NFS Server Setup](./volume/nfs/volume-nfs-readme.md):** A guide to installing and configuring an NFS server for your cluster.
- **[NFS CSI Driver and StorageClass](./volume/class/volume-class-readme.md):** Instructions for installing the NFS CSI driver and setting up a StorageClass for dynamic provisioning.

### MetalLB Installation and Configuration for Kubernetes

For MetalLB to function correctly in Layer 2 mode, you need to allow traffic on `TCP` and `UDP` port `7946` between all nodes in the cluster.

First, install MetalLB to your cluster by applying the official manifest

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.7/config/manifests/metallb-native.yaml
```

Wait for the MetalLB pods to be up and running. You can check their status with the following command:

```bash
kubectl get pods -n metallb-system -w
```

Next, you need to configure MetalLB to use a pool of IP addresses. Create a file named `metallb-config.yaml` with the following content.

```yml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.100.240-192.168.100.254
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - production-pool
  nodeSelectors:
  - matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
```

**Note**: Adjust the IP address range in the addresses field to match your network configuration. This should be a range of unused IP addresses on your network.

Apply the configuration to your cluster:

```bash
kubectl apply -f metallb-config.yaml
```

Verifying the Installation

```bash
kubectl get pods -n metallb-system
```

**Note:** All pods in the `metallb-system` namespace must be in a `Running` state for MetalLB to operate correctly.

### Setup Ingress Controller

Install the Nginx Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
```

Verify the installation:

```bash
# Check that the pod is in the "Running" state
kubectl get pods -n ingress-nginx

# Look for the IP in the EXTERNAL-IP column. This IP is very important!
kubectl get svc -n ingress-nginx
```

**Important**: The `EXTERNAL-IP` of the `ingress-nginx-controller` service is the IP address that will be used to access your Ingress resources. If it shows `<pending>`, you may need to wait a few minutes or check your MetalLB configuration.

### Test the Ingress Controller

For validating that your Ingress controller is working correctly, you can create a simple Nginx application and an Ingress resource.

Create a Namespace for test applications:

```bash
kubectl create namespace nginx-test
```

Create the Nginx Test Application `nginx-test-app.yml`

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test-deployment
  namespace: nginx-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
  namespace: nginx-test
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f nginx-test-app.yml
```

Complete and Apply the Ingress Manifest `ingress-principal.yml`

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-principal
  namespace: nginx-test
spec:
  ingressClassName: nginx
  rules:
  - host: "test.nginx-test.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-service
            port:
              number: 80
```

Apply the Ingress manifest:

```bash
kubectl apply -f ingress-principal.yml
```

### Test the Configuration 

This method is suitable for local testing without needing a public `DNS` entry.
Find the External IP of your Nginx Ingress Controller:

```bash
# Execute the following command and look for the IP address in the EXTERNAL-IP column for the ingress-nginx-controller service:
kubectl get svc -n ingress-nginx
```

Open `/etc/hosts` (Linux/macOS) or `C:\Windows\System32\drivers\etc\hosts` (Windows) with administrator privileges. Add the following line, replacing the example `IP` with your actual `LOCAL-IP`:

```bash
LOCAL-IP    test.nginx-test.com
```

Save the file and open your web browser. Navigate to http://test.nginx-test.com. You should see the default Nginx welcome page, confirming that your Ingress is routing traffic correctly to your `nginx-test-deployment`.

After testing, you can remove the entry from your `hosts` and delete the test namespace:

```bash
kubectl delete namespace nginx-test
```

### Setting Up an Internal-Only Ingress Controller

**Note** For services that should only be accessible from within the Kubernetes cluster (e.g., databases, internal APIs like MinIO), you can deploy a second, private Ingress controller. This controller will use a `ClusterIP` service, making it unreachable from outside the cluster. We will use Helm to install a new instance of the NGINX Ingress controller into a dedicated namespace (`ingress-nginx-internal`).

Add the Helm Repository

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

Install the Internal NGINX Ingress Controller

```bash
helm install ingress-nginx-internal ingress-nginx/ingress-nginx \
  --namespace ingress-nginx-internal \
  --create-namespace \
  --set controller.service.type=ClusterIP \
  --set controller.ingressClassResource.name=nginx-internal \
  --set controller.ingressClassResource.controllerValue="k8s.io/ingress-nginx-internal" \
  --set controller.electionID=ingress-nginx-internal-leader \
  --set controller.ingressClassResource.default=false
```

Verify the Internal Controller Installation

```bash
kubectl get pods -n ingress-nginx-internal
```

Now, check the service. Note that it has a `CLUSTER-IP` but no `EXTERNAL-IP`.

```bash
kubectl get svc -n ingress-nginx-internal
```

#### Test the Configuration - Creating an Internal-Only Ingress

To expose a service internally, create an Ingress manifest and set the `ingressClassName` to `nginx-internal`.
Create a file named `minio-internal-ingress.yaml`:

Create a Namespace for test applications:

```bash
kubectl create namespace nginx-test
```

Create the Nginx Test Application `nginx-test-app.yml`

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test-deployment
  namespace: nginx-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
  namespace: nginx-test
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f nginx-test-app.yml
```

Complete and Apply the Ingress Manifest `ingress-principal-local.yml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-principal-local
  namespace: nginx-test
spec:
  ingressClassName: nginx-internal # Use the internal class
  rules:
  - host: "test.nginx-test.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-service
            port:
              number: 80
```

Apply the manifest:

```bash
kubectl apply -f ingress-principal-local.yml
```

Now, any pod inside the cluster can access the service using the hostname `test.nginx-test.com`:

```bash
curl -H "Host: test.nginx-test.com" http://10.101.10.132
```

**Note**: But it will be completely inaccessible from outside the cluster.

After testing delete the test namespace:

```bash
kubectl delete namespace nginx-test
```

**Important**: Up to this point, you've configured and accessed your Kubernetes cluster locally. For exposing services via FRP (Fast Reverse Proxy) to the internet, consult the guide located in '../frp/frp-readme.md'.

---
## Troubleshooting: Full Cluster Reset

If you need to start over, this playbook will reset all nodes to clean state by running `kubeadm reset` and wiping configuration directories.

**WARNING**: This is a destructive action and will permanently delete your cluster configuration on the nodes.

```bash
ansible-playbook -i ./config/inventory.ini ./kubernetes/reset-cluster.yml --ask-become-pass
```

---
## Setting Up Remote `kubectl` Access

Run the Ansible playbook to install the `kubectl` command-line tool.

```bash
ansible-playbook -i ./config/inventory.ini  ./kubernetes/install-kubectl.yml --ask-become-pass
```

Fetch Cluster Configuration

```bash
scp <user>@<your-master-node-ip>:~/.kube/config ~/
```

Configure Local Environment

```bash
# Create the .kube directory if it doesn't exist
mkdir -p ~/.kube

# Move the config file to the correct location
mv ~/config ~/.kube/
```

Verify the Connection

```bash
kubectl get nodes
```

---
## Adding a New Worker Node to the Cluster

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
ansible-playbook -i ./config/inventory.ini ./kubernetes/add-hosts.yml --ask-become-pass
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
ansible-playbook -i ./config/inventory.ini ./kubernetes/join-workers.yml \
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