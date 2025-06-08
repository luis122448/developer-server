sudo kubeadm init \
  --control-plane-endpoint="192.168.100.171:6443" \
  --upload-certs \
  --pod-network-cidr="10.244.0.0/16" \
  --cri-socket="unix:///var/run/containerd/containerd.sock" \
  --kubernetes-version="v1.32.3"

kubeadm version
kubectl version
kubelet --version

You can now join any number of control-plane nodes running the following command on each as root:

sudo kubeadm join 192.168.100.171:6443 --token lnnvry.v08qc0sl22xfk6x9 \
        --discovery-token-ca-cert-hash sha256:487ba0b5ac5800aa62c59bad93ad773a04567de234b9623da63d582adf0adec6 \
        --control-plane --certificate-key 5b8c3019f1af246f7b744a32a7d5423b1e9e89e9035e255e6032736c6b31df27

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.171:6443 --token lnnvry.v08qc0sl22xfk6x9 \
        --discovery-token-ca-cert-hash sha256:487ba0b5ac5800aa62c59bad93ad773a04567de234b9623da63d582adf0adec6 

sudo kubeadm token create --print-join-command

kubeadm join n100-001:6443 --token n7jb0r.iytz232x18rcg6c6 --discovery-token-ca-cert-hash sha256:344189e12c5aeb7a4a47f3340840efa374bc5dfb8a2fbe938adab49c66af820e

kubeadm version
kubelet --version
kubectl version --client

[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0604 03:47:28.172596    6964 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.8" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.

sudo kubeadm reset -f --cri-socket="unix:///var/run/containerd/containerd.sock"
sudo rm -rf /etc/kubernetes/manifests/*
sudo rm -rf /etc/kubernetes/*
sudo rm -rf /var/lib/kubelet/* 
sudo rm -rf /var/lib/etcd/* 
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf $HOME/.kube
sudo systemctl restart containerd
sudo systemctl restart kubelet

/etc/containerd/config.toml

sudo kubeadm init --config kubeadm-config.yaml --upload-certs

sudo systemctl status kubelet

sudo rm -rf /etc/kubernetes/* # Limpia todo el directorio de configuración dse Kubernetes
sudo rm -rf /var/lib/kubelet/* # Limpia el directorio de trabajo del kubelet
sudo rm -rf /var/lib/etcd/* # Limpia el directorio de datos de etcd (IMPORTANTE para el primer nodo)
sudo rm -rf /etc/cni/net.d/* # Limpia la configuración CNI
# Limpia tu kubeconfig personal (si estás como el usuario luis122448)
rm -rf $HOME/.kube/config 

sudo journalctl -f -u containerd
sudo journalctl -f -u kubelet

sudo kubeadm config images list --kubernetes-version v1.32.3

sudo bash crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a

VERSION="v1.33.0"
ARCH="amd64"
wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-${ARCH}.tar.gz"

wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz"

tar zxvf "crictl-${VERSION}-linux-${ARCH}.tar.gz"

tar zxvf "crictl-v1.33.0-linux-amd64.tar.gz"

sudo mv crictl /usr/local/bin/

sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs <ID_DEL_CONTENEDOR_ETCD_SI_EXISTE>
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs <ID_DEL_CONTENEDOR_APISERVER_SI_EXISTE>

curl -kv https://192.168.100.181:6443/livez

sudo crictl ps -a
# O si no configuraste /etc/crictl.yaml:
# sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a


sudo kubeadm reset -f --cri-socket="unix:///var/run/containerd/containerd.sock"
sudo systemctl stop kubelet
sudo systemctl stop containerd
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /var/lib/containerd/*
sudo rm -rf /etc/kubernetes/*
sudo rm -rf /etc/cni/net.d/*
# Opcional pero recomendado para asegurar limpieza total:
# sudo reboot