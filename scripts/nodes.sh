#!/bin/bash
#
# Setup for Node servers

set -euxo pipefail

FIRST_RUN_WORKER=$HOME/first-run-worker.txt

if [[ -f "$FIRST_RUN_WORKER" ]]; then
    echo "Worker node alredy bootstraped"
    exit 0
fi

cat <<EOF >>/etc/profile.d/control_plane_docker_daemon.sh
export DOCKER_HOST=tcp://${CONTROL_PLANE_IP}
EOF

config_path="$SHARED_DIR/configs"

/bin/bash $config_path/join.sh -v

sudo -i -u vagrant bash <<EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown vagrant:vagrant /home/vagrant/.kube/config
NODENAME=$(hostname -s)
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
EOF

touch $FIRST_RUN_WORKER
