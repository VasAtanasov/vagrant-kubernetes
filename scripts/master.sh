#!/bin/bash
#

echo 'Setup for Control Plane (Master) servers'

set -euxo pipefail

NODENAME=$(hostname -s)
FIRST_RUN_CONTROL_PLANE=$HOME/first-run-control-plane.txt
if [[ -f "$FIRST_RUN_CONTROL_PLANE" ]]; then
  echo "Control Plane already bootstraped"
  exit 0
fi

POD_CIDR="192.168.0.0/16"

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

echo "* Copy configuration for $HOME ..."
mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="$SHARED_DIR/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

sudo -i -u vagrant bash <<EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown vagrant:vagrant /home/vagrant/.kube/config
EOF

kubeadm token create --print-join-command >$config_path/join.sh

# Install Calico Network Plugin

curl https://docs.projectcalico.org/manifests/calico.yaml -O

kubectl apply -f calico.yaml

# Install Metrics Server

#kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# # Install Kubernetes Dashboard

# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml

# # Create Dashboard User

# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: admin-user
#   namespace: kubernetes-dashboard
# EOF

# cat <<EOF | kubectl apply -f -
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: admin-user
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
# - kind: ServiceAccount
#   name: admin-user
#   namespace: kubernetes-dashboard
# EOF

# kubectl -n kubernetes-dashboard get secret "$(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}")" -o go-template="{{.data.token | base64decode}}" >> $config_path/token

touch $FIRST_RUN_CONTROL_PLANE
