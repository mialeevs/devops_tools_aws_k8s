#!/bin/bash
#

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Export the OS and CRI_O version values
echo "Exporting OS and CRIO Version"

export OS_VERSION=xUbuntu_22.04
export CRIO_VERSION=1.28

sudo curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg

sudo curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

# we can get the latest release details from https://cri-o.io/

sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

echo "Exporting kubernetes repositories and keyrings values"

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Updating the repositories"
# Update the repositiries
sudo apt-get update -y
sudo apt-get install cron -y


echo "Installing cri-o and kubernetes tools"

# Use the same versions to avoid issues with the installation.
sudo apt-get install -y cri-o cri-o-runc cri-tools kubelet kubeadm kubectl

sleep 5

echo "Start the cri-o service"
sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

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

sleep 5

# Use this if you have initialised the cluster with Calico network add on.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml -O
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

sleep 5
# ArgoCD cli resources
https://github.com/argoproj/argo-cd/releases/latest

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
# Get the password from the secret file
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

git clone https://github.com/mialeevs/devops_tools_aws_k8s.git

cd devops_tools_aws_k8s/config/stack/jenkins

kubectl apply -f jenkins_namespace.yaml

sleep 10

kubectl apply -f app 

sudo chown -R ubuntu:ubuntu /mnt

cd app

kubectl delete -f jenkins_deploy.yaml

sleep 10

kubectl apply -f jenkins_deploy.yaml

sleep 120
