#!/bin/sh -eux

disable_sudo_password() {
    local username="${1}"
    cp /etc/sudoers /etc/sudoers.bak
    bash -c "echo '${username} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

disable_sudo_password 'vagrant'

echo -n > /home/vagrant/.hushlogin