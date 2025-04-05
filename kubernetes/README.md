# Installation Kubernetes in Rasberry PI and N100 Intel

## Disable Swap

```bash
    ansible-playbook -i ./kubernetes/inventory.ini ./kubernetes/disable_swap.yml --ask-become-pass
```

## Configure Kernel

```bash
    ansible-playbook -i ./kubernetes/inventory.ini ./kubernetes/configure_kernel.yml --ask-become-pass
```

## Runtime Installation

```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
```
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


https://apt.kubernetes.io/ kubernetes-xenial main
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
