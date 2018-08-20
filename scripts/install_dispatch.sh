#!/bin/sh

# Install and init Helm
curl -Lo helm-linux-amd64.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz && tar -zxvf helm-linux-amd64.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/helm
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 
helm init --service-account tiller --wait

# Download Dispatch CLI
apt-get install -y jq
export LATEST=$(curl -s https://api.github.com/repos/vmware/dispatch/releases/latest | jq -r .name)
curl -OL https://github.com/vmware/dispatch/releases/download/$LATEST/dispatch-linux
chmod +x dispatch-linux
mv dispatch-linux /usr/local/bin/dispatch

# Setup install config
export DISPATCH_HOST=dispatch.example.com
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

# TODO: Remove
touch /tmp/spin
while [ -f /tmp/spin ]
do
  sleep 5
done

cat << EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["10.96.0.0/12"]
}
EOF
