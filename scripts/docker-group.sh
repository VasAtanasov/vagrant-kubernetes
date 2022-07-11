#!/bin/sh -eux

CURRENT_USER=${CURRENT_USER:-$USER}

if grep -q "docker" /etc/group; then
    echo "Docker group alredy exists, skipping creation"
else
    sudo groupadd docker
fi

EXISTS=$(grep -c "^${CURRENT_USER}:" /etc/passwd)
if [ $EXISTS -eq 0 ]; then
    echo "The user ${CURRENT_USER} does not exist"
else
    echo "The user ${CURRENT_USER} exists"
    sudo gpasswd -a ${CURRENT_USER} docker
fi