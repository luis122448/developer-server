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

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/k8s_prep.yml --ask-become-pass
```

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/install_docker.yml --ask-become-pass
```

```bash
    ansible-playbook -i ./config/inventory.ini ./kubernetes/kubectl.yml --ask-become-pass
```

## Init First Master ()

Conected in `n100-001`

```bash
sudo kubeadm init \
  --control-plane-endpoint "192.168.100.200:6443" \   # VIP del LB
  --upload-certs \                                # habilita compartir certs
  --pod-network-cidr=10.244.0.0/16                # rango de pods (Flannel)
```

- name: Aplicar manifest de Flannel
  kubernetes.core.k8s:
    state: present
    kubeconfig: /etc/kubernetes/admin.conf
    src: https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml