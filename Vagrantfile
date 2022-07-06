# -*- mode: ruby -*-
# vi: set ft=ruby :

KUBERNETES_VERSION = "1.23.8-00"

VAGRANT_BOX = "debian/bullseye64"
CPUS_CONTROL_PANE_NODE = 2
CPUS_WORKER_NODE = 2
MEMORY_CONTROL_PANE_NODE = 6000
MEMORY_WORKER_NODE = 6000
WORKER_NODES_COUNT = 1
CONTROL_PLANE_COUNT = 1
TOTAL_NODES_COUNT = CONTROL_PLANE_COUNT + WORKER_NODES_COUNT

IP_NW = "192.168.81."
IP_START = 210
POD_NETWORK = "192.168.0.0/16"

VAGRANTFILE_API_VERSION = "2"
SHARED_DIR = "/home/vagrant/shared"
VAGRANT_ASSETS = File.expand_path("assets")

SCRIPTS = File.expand_path("scripts")
SCRIPTS_PATH = "/tmp" # The location where vagrant will upload the scripts on the guest

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.box = VAGRANT_BOX
  config.vm.box_check_update = false
  config.vm.post_up_message = "" # official debian images have post_up_message, this removes it
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |vb, override|
    vb.gui = false
    vb.check_guest_additions = false

    vb.customize ["modifyvm", :id, "--groups", "/k8s"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]

    override.vm.synced_folder "#{VAGRANT_ASSETS}", "#{SHARED_DIR}"
  end

  CONTROL_PLANE_IP = "#{IP_NW}#{IP_START + 1}"

  config.vm.provision "shell",
    env: { "CURRENT_USER" => "vagrant" },
    name: "Bootstrapping common settings",
    path: "#{SCRIPTS}/common.sh"

  config.vm.provision "shell",
    env: { "CURRENT_USER" => "vagrant" },
    name: "Bootstrapping container runtime",
    path: "#{SCRIPTS}/docker.sh"

  config.vm.provision "shell",
    env: { "KUBERNETES_VERSION" => "#{KUBERNETES_VERSION}", "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "SHARED_DIR" => "#{SHARED_DIR}" },
    name: "Bootstrapping kubernetes",
    path: "#{SCRIPTS}/kubernetes.sh"

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
      vb.memory = MEMORY_CONTROL_PANE_NODE
      vb.cpus = CPUS_CONTROL_PANE_NODE
    end

    node.vm.provision "shell",
                      env: { "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "POD_CIDR" => "#{POD_NETWORK}", "SHARED_DIR" => "#{SHARED_DIR}" },
                      name: "Installing Control Plane Node",
                      path: "#{SCRIPTS}/control_plane.sh"
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
      end

      node.vm.provision "shell",
                        env: { "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "SHARED_DIR" => "#{SHARED_DIR}" },
                        name: "Installing Worker Node node-#{i}",
                        path: "#{SCRIPTS}/nodes.sh"
    end
  end
end
