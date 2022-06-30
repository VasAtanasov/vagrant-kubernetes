# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

SETTINGS_FILE = File.expand_path('settings.yml')
if File.exist? SETTINGS_FILE then
  settings = YAML.load_file SETTINGS_FILE
else
  abort "settings.yml was not found"
end

VAGRANT_ASSETS = File.expand_path('assets')
if ! File.exists? VAGRANT_ASSETS then
  VAGRANT_ASSETS = File.expand_path(Dir.pwd)
end

VAGRANTFILE_API_VERSION = settings['VAGRANTFILE_API_VERSION'] || "2"
KUBERNETES_VERSION = settings['K8S_VERSION'] || "1.23.7-00"
SHARED_DIR = settings['SYNCED_FOLDER']
SCRIPTS = File.expand_path('scripts')

machines = settings['machines']

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  machines.each do |machine_name, machine|
    machine_hostname = machine['hostname']
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.ssh.insert_key = false
    config.vm.allow_hosts_modification = false

    config.vm.define machine_name do |m|
      m.vm.box = machine['box']
      m.vm.box_check_update = false
      m.vm.hostname = machine_hostname

      #################
      # Networking :: Private
      #################b 
      if machine['network'].include? 'private'
        m.vm.network "private_network", ip: "#{machine['network']['private']['address']}"
      end

      #################
      # Networking :: Public
      #################
      if machine['network'].include? 'public'
        public_ip_address = "#{machine['network']['public']['address']}"
        m.vm.network "public_network", ip: public_ip_address, hostname: true, bridge: "ens33"
      end

      #################
      # Networking :: Port forwarding
      #################
      if machine.include? 'forwarded_port'
        machine["forwarded_port"].each do |port|
          m.vm.network "forwarded_port", guest: port["guest"], host: port["host"], auto_correct: true
        end
      end

      #################
      # Networking :: /etc/hosts
      #################
      machines.each do |machine_name, opts|
        m.vm.provision "shell",
          env: {"IP" => "#{opts['network']['private']['address']}", "HOSTNAME" => "#{opts['hostname']}", "HOST_ALIAS" => "#{machine_name}"},
          name: "===> Appendig #{machine_name} to /etc/hosts", path: "#{SCRIPTS}/hosts.sh"
      end

      #################
      # Cluster initialization
      #################
      if machine["node"] == "master"
        m.vm.provision "shell",
          env: {"MASTER_IP" => "#{machine['network']['private']['address']}", "SHARED_DIR" => "#{SHARED_DIR}"},
          name: "Installing Controll Plane Node", path: "#{SCRIPTS}/master.sh"
      else
        m.vm.provision "shell",
          env: {"SHARED_DIR" => "#{SHARED_DIR}"},
          name: "Installing Worker Node #{machine_hostname}", path: "#{SCRIPTS}/nodes.sh"
      end

      #################
      # Provider :: Configuration for virtualbox provider
      #################
      m.vm.provider "virtualbox" do |vb, override|
        vb.name = machine_name
        vb.memory = machine['memory']
        vb.cpus = machine['cpu']
        
        vb.customize ["modifyvm", :id, "--vram",               machine['vram']]
        vb.customize ["modifyvm", :id, "--groups",             "/k8s"]

        vb.check_guest_additions = false
        override.vm.synced_folder "#{VAGRANT_ASSETS}", "#{SHARED_DIR}"
      end


    end

  end

  config.vm.provision "shell", 
    env: {"KUBERNETES_VERSION" => "#{KUBERNETES_VERSION}", "SHARED_DIR" => "#{SHARED_DIR}"},
    name: "Boostraping container runtime and kubernetes", path: "#{SCRIPTS}/boostrap.sh"

end
