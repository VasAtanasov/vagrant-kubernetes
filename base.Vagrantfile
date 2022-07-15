# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"

# Someone may need to (locally) override the VM config for some specific task...
vmconfig = YAML.load_file File.join(File.dirname(__FILE__), ".vmconfig.yml")

VAGRANT_BOX = vmconfig["DEFAULT_VAGRANT_BOX"]
VAGRANT_BOX_VERSION = vmconfig["DEFAULT_VAGRANT_BOX_VERSION"]
CPUS_CONTROL_PANE_NODE = vmconfig["CPUS_CONTROL_PANE_NODE"]
CPUS_WORKER_NODE = vmconfig["CPUS_WORKER_NODE"]
MEMORY_CONTROL_PANE_NODE = vmconfig["MEMORY_CONTROL_PANE_NODE"]
MEMORY_WORKER_NODE = vmconfig["MEMORY_WORKER_NODE"]
WORKER_NODES_COUNT = vmconfig["WORKER_NODES_COUNT"]
CONTROL_PLANE_COUNT = vmconfig["CONTROL_PLANE_COUNT"]
TOTAL_NODES_COUNT = CONTROL_PLANE_COUNT + WORKER_NODES_COUNT

IP_NW = vmconfig["IP_NW"]
IP_START = vmconfig["IP_START"]
POD_NETWORK = vmconfig["POD_NETWORK"]
CONTROL_PLANE_IP = "#{IP_NW}#{IP_START + 1}"

VAGRANTFILE_API_VERSION = vmconfig["VAGRANTFILE_API_VERSION"]
SHARED_DIR = vmconfig["SHARED_DIR"]
VAGRANT_ASSETS = File.expand_path("assets")
CONFIGS_PATH = "#{SHARED_DIR}/configs"

SCRIPTS = File.expand_path("scripts")
SCRIPTS_PATH = vmconfig["SCRIPTS_PATH"] # The location where vagrant will upload the scripts on the guest

KUBERNETES_VERSION = vmconfig["DEFAULT_KUBERNETES_VERSION"]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder ".", "/vagrant", type: "nfs", disabled: true
  config.vm.box = VAGRANT_BOX
  config.vm.box_version = VAGRANT_BOX_VERSION
  config.vm.box_check_update = false
  config.vm.post_up_message = "" # official debian images have post_up_message, this removes it
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |vb, override|
    vb.gui = false
    vb.check_guest_additions = false

    vb.customize ["modifyvm", :id, "--groups", "/k8s"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
    vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
    override.vm.synced_folder "#{VAGRANT_ASSETS}", "#{SHARED_DIR}"
  end

  config.vm.provision "shell",
                      name: "Bootstrapping common settings",
                      path: "#{SCRIPTS}/common.sh"

  config.vm.provision "shell",
                      name: "Setting sshd configuration",
                      path: "#{SCRIPTS}/sshd.sh"

  (1..TOTAL_NODES_COUNT).each do |i|
    config.vm.provision "shell",
      name: "===> Appendig node-#{i}.k8s to /etc/hosts",
      env: { "IP" => "#{IP_NW}#{IP_START + i}", "HOSTNAME" => "node-#{i}.k8s", "HOST_ALIAS" => "node-#{i}" },
      path: "#{SCRIPTS}/setup-hosts.sh"
  end
end
