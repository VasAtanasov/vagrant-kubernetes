# -*- mode: ruby -*-
# vi: set ft=ruby :

include_base_vagrantfile = "./base.Vagrantfile"
load include_base_vagrantfile if File.exist?(include_base_vagrantfile)

VAGRANT_BOX = "vasatanasov/debian-11.3-k8s-docker"
VAGRANT_BOX_VERSION = "202207.15.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = VAGRANT_BOX
  config.vm.box_version = VAGRANT_BOX_VERSION

  config.vm.provision "shell", inline: "echo #{KUBERNETES_VERSION} > /tmp/k8s-version"

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
                      name: "Installing Control Plane Node",
                      env: { "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "POD_CIDR" => "#{POD_NETWORK}", "CONFIGS_PATH" => "#{CONFIGS_PATH}" },
                      path: "#{SCRIPTS}/control_plane.sh"
  end

  # Kubernetes Worker Nodes
  (2..TOTAL_NODES_COUNT).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}.k8s"
      node.vm.network "private_network", ip: "#{IP_NW}#{IP_START + i}"

      node.vm.provider :virtualbox do |vb, override|
        vb.name = "node-#{i}"
        vb.memory = MEMORY_WORKER_NODE
        vb.cpus = CPUS_WORKER_NODE
      end

      node.vm.provision "shell",
                        name: "Installing Worker Node node-#{i}",
                        env: { "CONTROL_PLANE_IP" => "#{CONTROL_PLANE_IP}", "CONFIGS_PATH" => "#{CONFIGS_PATH}" },
                        path: "#{SCRIPTS}/nodes.sh"
    end
  end
end
