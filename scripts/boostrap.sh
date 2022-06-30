#!/bin/bash
#

echo 'Common setup for all servers (Control Plane and Nodes)'

set -euxo pipefail

FIRST_RUN_MARKER=$HOME/first-run-bootstrap.txt
echo $HOME
if [[ -f "$FIRST_RUN_MARKER" ]]; then
    echo "Machine already bootstraped"
    exit 0
fi

echo 'Create the .conf file to load the modules at boot ...'
modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
br_netfilter
EOF

# Set up required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo '* Install iptables and switch it iptables to legacy version ...'
apt-get update
apt-get install -y iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --query iptables

echo '* Turn off the swap ...'
swapoff -a
sed -i '/swap/ s/^/#/' /etc/fstab 

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y

free -h
cat /etc/fstab

echo '* Install other required packages ...'
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq

echo '* Download and install the Docker repository key ...'
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo '* Add the Docker repository ...'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/nulL

echo '* Install the required container runtime packages ...'
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

echo '* Adjust container runtime configuration ...'
mkdir -p /etc/docker

cat <<EOF >> /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
  "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable docker
systemctl daemon-reload
systemctl restart docker

echo "Docker runtime installed susccessfully"

echo '* Add vagrant user to docker group ...'
usermod -aG docker vagrant

echo '* Download and install the Kubernetes repository key ...'
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo '* Add the Kubernetes repository ...'
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update

echo "* Install the selected ($KUBERNETES_VERSION) version ..."
apt-get update
if [ $KUBERNETES_VERSION != 'latest' ]; then 
  apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
else
  apt-get install -y kubelet kubeadm kubectl
fi

echo '* Exclude the Kubernetes packages from being updated ...'
apt-mark hold kubelet kubeadm kubectl

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

touch $FIRST_RUN_MARKER