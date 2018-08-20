#!/bin/sh

kubeadm init --pod-network-cidr=10.244.0.0/16

# Setup config for kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown kube:kube $HOME/.kube/config

# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

# Allow scheduling pods on Master Node
kubectl taint nodes --all node-role.kubernetes.io/master-
