# -*- mode: ruby -*-
# vi: set ft=ruby :

include_base_vagrantfile = "./base.Vagrantfile"
load include_base_vagrantfile if File.exist?(include_base_vagrantfile)

VAGRANT_BOX = "vasatanasov/debian-11.3"
VAGRANT_BOX_VERSION = "202207.15.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = VAGRANT_BOX
  config.vm.box_version = VAGRANT_BOX_VERSION

  NFS_SERVER_IP = "#{IP_NW}#{12}"

  config.vm.provision "shell",
                      name: "===> Ensure nfs-common is installed",
                      inline: <<~SCRIPT
                        apt-get update && apt-get install -y nfs-common
                      SCRIPT

  config.vm.provision "shell",
                      name: "===> Appendig nfs-server to /etc/hosts",
                      inline: <<~SCRIPT
                        echo '#{NFS_SERVER_IP} nfs-server' >> /etc/hosts
                      SCRIPT

  (1..TOTAL_NODES_COUNT).each do |i|
    config.vm.provision "shell",
      name: "===> Appendig nfs-server to /etc/hosts",
      env: { "IP" => "#{NFS_SERVER_IP}", "HOSTNAME" => "nfs-server", "HOST_ALIAS" => "" },
      path: "#{SCRIPTS}/setup-hosts.sh"
  end

  config.vm.define "nfs-server" do |nfs|
    nfs.vm.hostname = "nfs-server"
    nfs.vm.network "private_network", ip: "#{NFS_SERVER_IP}"

    nfs.vm.provider :virtualbox do |vb, override|
      vb.name = "nfs-server"
      vb.memory = MEMORY_WORKER_NODE
      vb.cpus = CPUS_WORKER_NODE
    end

    nfs.vm.provision "shell",
                     name: "===> Ensure nfs-server is instaled and configured",
                     inline: <<~SCRIPT
                       apt-get update && apt-get install -y nfs-kernel-server
                       mkdir -p /data
                       chown nobody:nogroup /data
                       chmod -R 777 /data
                       echo '/data *(rw,sync,no_subtree_check)' >> /etc/exports
                       export -a
                       systemctl restart nfs-server
                     SCRIPT
  end
end
