#!/bin/sh -eux

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

update_packages() {
    apt-get update -qq >/dev/null
}

if [[ $(id -u) -ne 0 ]]; then
    echo "Bootstrapper, APT-GETs all the things -- run as root..."
    exit 1
fi

if command_exists docker; then
    echo "Removing previouse versions of docker"
    apt-get remove -y docker docker-engine docker.io containerd runc
    apt-get purge -y docker-ce docker-ce-cli containerd.io
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
else
    echo "There is no docker installed"
fi

pre_reqs="apt-transport-https ca-certificates curl gnupg lsb-release"

echo "Updateing the apt package index and install packages to allow apt to use a repository over HTTPS"

update_packages
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pre_reqs >/dev/null

echo "Adding Docker's official GPG key"

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/nulL

echo "Installing Docker Engine"

update_packages
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null
