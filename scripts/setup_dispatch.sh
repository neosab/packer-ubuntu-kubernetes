#!/bin/bash

if [[ $EUID != 0 ]]; then
    echo "Please run the script as 'sudo $0'"
    exit 1
fi

kubeadm init --pod-network-cidr=10.244.0.0/16

# Setup config for kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown kube:kube $HOME/.kube/config

# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

# Allow scheduling pods on Master Node
kubectl taint nodes --all node-role.kubernetes.io/master-

# Initialize Helm
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
helm init --service-account tiller --wait

export DISPATCH_HOST=$(ifconfig eth0 | grep "inet addr" | cut -d: -f2 | awk '{print $1}')
cat << EOF > config.yaml
apiGateway:
  host: $DISPATCH_HOST
dispatch:
  host: $DISPATCH_HOST
  debug: true
  skipAuth: true
kafka:
  chart:
    version: 0.8.5
    opts:
      persistence.enabled: false
      replicas: 1
dockerRegistry:
  chart:
    version: 1.5.1
EOF

# timeout:1200 If network is slow, the image pulls may be slower and hence the large timeout
dispatch install --file config.yaml --debug --timeout 1200