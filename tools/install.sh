#!/bin/bash
#

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common


# Export the OS and CRI_O version values
echo "Exporting OS and CRIO Version"

export OS_VERSION=xUbuntu_22.04
export CRIO_VERSION=v1.30

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

sudo curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

sudo echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

echo "Installing cri-o"
sudo apt-get update -y
sudo apt-get install cri-o -y

sleep 5

echo "Start the cri-o service"
sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio


echo "Updating the repositories"
# Update the repositiries
sudo apt-get update -y
sudo apt-get install cron -y

echo "Exporting kubernetes repositories and keyrings values"

sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Installing kubernetes tools"

# Use the same versions to avoid issues with the installation.
sudo apt-get install -y kubelet kubeadm kubectl


sleep 5

echo "Holding the tool versions"
sudo apt-mark hold cri-o kubelet kubeadm kubectl

cat <<EOF | sudo tee /etc/sysctl.conf
vm.max_map_count = 262144
EOF

sudo sysctl -p

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

echo "Disabling the SWAP"
# Disable the swap
sudo swapoff -a
(sudo crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | sudo crontab - || true

sleep 5

#sudo kubeadm init --pod-network-cidr=192.168.0.0/16
echo "initialising the cluster"

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/crio/crio.sock

sleep 5
echo "Copying the config file"

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


sleep 5

echo "untaint controlplane node"
kubectl taint nodes $(kubectl get nodes -o=jsonpath='{.items[].metadata.name}') node.kubernetes.io/not-ready:NoSchedule-
kubectl taint nodes $(kubectl get nodes -o=jsonpath='{.items[].metadata.name}') node-role.kubernetes.io/control-plane=:NoSchedule-
kubectl get node -o wide
kubectl label node $(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}') color=orange

sleep 5

# Use this if you have initialised the cluster with Calico network add on.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml


sleep 5

git clone https://github.com/mialeevs/kubernetes_installation_crio.git
cd kubernetes_installation_crio/
kubectl apply -f metrics-server.yaml
cd ..
rm -rf kubernetes_installation_crio

sleep 5

# Non HA installation
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.12.2/manifests/install.yaml

# Installing HELM
sleep 30
echo "Installing Helm"
sudo apt-get update -y
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

sleep 5
sudo apt-get install bash-completion -y
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "alias c=clear" >> ~/.bashrc
source ~/.profile

# Install ArgoCD cli
wget https://github.com/argoproj/argo-cd/releases/download/v2.12.2/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
sleep 20
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'

# Create a node label and namespaces
kubectl create ns jenkins
kubectl create ns sonar
kubectl create ns nexus
# Create the folders
mkdir -p /home/ubuntu/data/jenkins
mkdir -p /home/ubuntu/data/postgres_data
mkdir -p /home/ubuntu/data/sonarqube_data
mkdir -p /home/ubuntu/data/sonarqube_logs
mkdir -p /home/ubuntu/data/sonarqube_extensions
mkdir -p /home/ubuntu/data/nexus-data


# Get the password from the secret file
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

git clone -b  new https://github.com/mialeevs/devops_tools_aws_k8s.git
cd devops_tools_aws_k8s/config/stack
kubectl apply -f storage.yaml
sleep 10
kubectl apply -f jenkins
sleep 60
