# -*- mode: ruby -*-
# vi: set ft=ruby :

KUBERNETES_VERSION = "1.23.8-00"

VAGRANT_BOX = "boxomatic/debian-11"
CPUS_MASTER_NODE = 2
CPUS_WORKER_NODE = 2
MEMORY_MASTER_NODE = 6000
MEMORY_WORKER_NODE = 6000
WORKER_NODES_COUNT = 1
CONTROL_PLANE_COUNT = 1
TOTAL_NODES_COUNT = CONTROL_PLANE_COUNT + WORKER_NODES_COUNT

IP_NW = "192.168.81."
IP_START = 210
POD_NETWORK = "192.168.0.0/16"

VAGRANTFILE_API_VERSION = "2"
SHARED_DIR = "/home/vagrant/shared"
SCRIPTS = File.expand_path("scripts")
VAGRANT_ASSETS = File.expand_path("assets")

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.box = VAGRANT_BOX
  config.vm.box_check_update = false

  config.ssh.insert_key = false

  CONTROL_PLANE_IP = "#{IP_NW}#{IP_START + 1}"

  config.vm.provision "shell",
    env: { "KUBERNETES_VERSION" => "#{KUBERNETES_VERSION}", "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "SHARED_DIR" => "#{SHARED_DIR}" },
    name: "Bootstrapping container runtime and kubernetes",
    path: "#{SCRIPTS}/boostrap.sh"

  (1..TOTAL_NODES_COUNT).each do |i|
    config.vm.provision "shell",
      env: { "IP" => "#{IP_NW}#{IP_START + i}", "HOSTNAME" => "node-#{i}.k8s", "HOST_ALIAS" => "node-#{i}" },
      name: "===> Appendig node-#{i}.k8s to /etc/hosts",
      path: "#{SCRIPTS}/hosts.sh"
  end
  
  # Kubernetes Control Plane Server
  config.vm.define "node-1" do |node|
    node.vm.hostname = "node-1.k8s"
    node.vm.network "private_network", ip: "#{CONTROL_PLANE_IP}"

    node.vm.provider :virtualbox do |vb, override|
      vb.name = "node-1"
      vb.memory = MEMORY_MASTER_NODE
      vb.cpus = CPUS_MASTER_NODE

      vb.customize ["modifyvm", :id, "--vram", 128]
      vb.customize ["modifyvm", :id, "--groups", "/k8s"]

      vb.check_guest_additions = false
      override.vm.synced_folder "#{VAGRANT_ASSETS}", "#{SHARED_DIR}"
    end

    node.vm.provision "shell",
                      env: { "MASTER_IP" => "#{IP_NW}#{IP_START + 1}", "POD_CIDR" => "#{POD_NETWORK}", "SHARED_DIR" => "#{SHARED_DIR}" },
                      name: "Installing Control Plane Node",
                      path: "#{SCRIPTS}/master.sh"
  end

  # Kubernetes Worker Nodes
  (2..(WORKER_NODES_COUNT + CONTROL_PLANE_COUNT)).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}.k8s"
      node.vm.network "private_network", ip: "#{IP_NW}#{IP_START + i}"

      node.vm.provider :virtualbox do |vb, override|
        vb.name = "node-#{i}"
        vb.memory = MEMORY_WORKER_NODE
        vb.cpus = CPUS_WORKER_NODE

        vb.customize ["modifyvm", :id, "--vram", 128]
        vb.customize ["modifyvm", :id, "--groups", "/k8s"]

        vb.check_guest_additions = false
        override.vm.synced_folder "#{VAGRANT_ASSETS}", "#{SHARED_DIR}"
      end

      node.vm.provision "shell",
                        env: { "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "SHARED_DIR" => "#{SHARED_DIR}" },
                        name: "Installing Worker Node node-#{i}",
                        path: "#{SCRIPTS}/nodes.sh"
    end
  end
end
