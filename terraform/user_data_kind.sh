#!/bin/sh

set -x # for post-mortem debugging

# install kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

usermod -aG docker ubuntu

# install helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# increase inotify limits
cat <<EOF >> /etc/sysctl.conf
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=524288
EOF

sudo sysctl -p

mkdir -p /install/data

# kind cluster configuration without default CNI
cat <<EOF > /install/data/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${kind_cluster_name}
networking:
  # the default CNI will not be installed
  disableDefaultCNI: true
  apiServerAddress: "127.0.0.1"
  apiServerPort: 6443
EOF

# create kind cluster
kind create cluster --config /install/data/kind-config.yaml --kubeconfig /install/data/${kind_cluster_name}.config

# install cilium helm repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# get cilium install manifests
cat <<EOF > /install/data/cilium-values.yaml
envoyConfig:
  enabled: true
  secretsNamespace:
    create: true
    name: cilium-secrets
EOF

helm template cilium cilium/cilium --version 1.15.0 --namespace kube-system -f /install/data/cilium-values.yaml > /install/data/cilium-install.yaml

# install cilium
KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl apply -f /install/data/cilium-install.yaml

# create testing k8s resources
KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl create ns test-deny
KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl create ns test-allow

# Wait until the 'default' service account exists in 'test-deny' namespace
until KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl get serviceaccount default -n test-deny >/dev/null 2>&1; do
    sleep 5
done

# Wait until the 'default' service account exists in 'test-allow' namespace
until KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl get serviceaccount default -n test-allow >/dev/null 2>&1; do
    sleep 5
done

KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl run curl -n test-deny --image=curlimages/curl:latest --image-pull-policy=IfNotPresent -- sleep 3600
KUBECONFIG=/install/data/${kind_cluster_name}.config kubectl run curl -n test-allow --image=curlimages/curl:latest --image-pull-policy=IfNotPresent -- sleep 3600

touch /setup-complete