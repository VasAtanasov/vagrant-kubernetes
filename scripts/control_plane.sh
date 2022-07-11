#!/bin/bash

set -euxo pipefail

FIRST_RUN_CONTROL_PLANE=$HOME/first-run-control-plane.txt
if [[ -f "$FIRST_RUN_CONTROL_PLANE" ]]; then
    echo "Control Plane already bootstraped"
    exit 0
fi

echo 'Setup for Control Plane (Master) servers'

NODENAME=$(hostname -s)
KUBERNETES_VERSION=$(cut -d - -f 1 /tmp/k8s-version)

kubeadm config images pull

echo "* Initialize Kubernetes cluster ..."
if [ $KUBERNETES_VERSION != 'latest' ]; then
    kubeadm init --kubernetes-version=$KUBERNETES_VERSION --apiserver-advertise-address=$CONTROL_PLANE_IP --apiserver-cert-extra-sans=$CONTROL_PLANE_IP --pod-network-cidr=$POD_CIDR --node-name "$NODENAME"
else
    kubeadm init --apiserver-advertise-address=$CONTROL_PLANE_IP --apiserver-cert-extra-sans=$CONTROL_PLANE_IP --pod-network-cidr=$POD_CIDR --node-name "$NODENAME"
fi

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

if [ -d $CONFIGS_PATH ]; then
    rm -f $CONFIGS_PATH/*
else
    mkdir -p $CONFIGS_PATH
fi

echo "* Externalize admin.conf ..."
cp -i /etc/kubernetes/admin.conf $CONFIGS_PATH/config
touch $CONFIGS_PATH/join.sh
chmod +x $CONFIGS_PATH/join.sh

echo "* Copy configuration for root ..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown -R root:root /root/.kube

echo "* Copy configuration for vagrant ..."
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

kubeadm token create --print-join-command >$CONFIGS_PATH/join.sh

# Install Network Plugin

echo "* Install Pod Network plugin (Antrea) ..."
TAG=${ANTREA_VERSION:-v1.7.0}
kubectl apply -f https://github.com/antrea-io/antrea/releases/download/$TAG/antrea.yml

# echo "* Install Pod Network plugin (Flannel) ..."
# wget -q https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -O /tmp/kube-flannel.yaml
# sed -i '/--kube-subnet-mgr/ a CHANGEME' /tmp/kube-flannel.yaml
# sed -i "s/CHANGEME/        - --iface=${CONTROL_PLANE_IP}/" /tmp/kube-flannel.yaml
# kubectl apply -f /tmp/kube-flannel.yaml

# echo "* Install Pod Network plugin (Calico) ..."
# kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
# wget -q https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml -O /tmp/custom-resources.yaml
# sed -i "s@192.168.0.0/16@${POD_CIDR}@g" /tmp/custom-resources.yaml
# kubectl create -f /tmp/custom-resources.yaml

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

# kubectl -n kubernetes-dashboard get secret "$(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}")" -o go-template="{{.data.token | base64decode}}" >> $CONFIGS_PATH/token

touch $FIRST_RUN_CONTROL_PLANE
