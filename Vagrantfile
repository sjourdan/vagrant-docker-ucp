# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

# defaults if not set in config.rb
$vm_box = "sjourdan/ubuntu-1404-k42"
# $vm_box = "centos/7"

# UCP master parameters
$ucp_master_memory = "2048"
$ucp_master_ip = "192.168.100.10"

# UCP replicas parameters
$ucp_replicas_prefix = "ucp-replica"
$ucp_replicas_number = 2
$ucp_replica_memory = "2048"

# UCP nodes parameters
$ucp_nodes_number = 1
$ucp_nodes_prefix = "ucp-node"
$ucp_node_memory = "2048"

# load the configuration file
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

if File.exist?(CONFIG)
  require CONFIG
end

# we want to use vagrant-cachier plugin
%w(vagrant-cachier).each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "#{plugin} plugin is not installed! Please install it using `vagrant plugin install #{plugin}`"
  end
end

# let's go vagrant
Vagrant.configure(2) do |config|
  config.vm.provision "shell", inline: "echo BOOTSTRAPPING DOCKER UCP DEMO"

  # $ vagrant plugin install vagrant-vbguest
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
    config.vbguest.auto_reboot = true
  end

  # Let's use some cache to speed things up
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  # configure an UCP master
  config.vm.define "ucp-master", primary: true do |master|
    master.vm.box = $vm_box
    master.vm.hostname = "ucp-master"

    master.vm.provider "virtualbox" do |vb|
      vb.memory = $ucp_master_memory
    end

    master.vm.network "private_network", ip: $ucp_master_ip

    # pull some required Docker images
    master.vm.provision "docker" do |d|
      d.pull_images "docker/ucp"
    end

  end

  # launch as many UCP nodes as needed
  (1..$ucp_nodes_number).each do |i|

    config.vm.define vm_name = "%s-%02d" %
    [$ucp_nodes_prefix, i] do |config|
      config.vm.hostname = vm_name
      config.vm.box = $vm_box

      config.vm.provider :virtualbox do |vb|
        vb.memory = $ucp_node_memory
      end

      ip = "192.168.100.#{i+100}"
      config.vm.network :private_network, ip: ip

      # pull some required Docker images
      config.vm.provision "docker" do |d|
        d.pull_images "docker/ucp"
      end
    end
  end

  # launch as many UCP replicas as needed
  (1..$ucp_replicas_number).each do |i|

    config.vm.define vm_name = "%s-%02d" %
    [$ucp_replicas_prefix, i] do |config|
      config.vm.hostname = vm_name
      config.vm.box = $vm_box

      config.vm.provider :virtualbox do |vb|
        vb.memory = $ucp_replica_memory
      end

      ip = "192.168.100.#{i+50}"
      config.vm.network :private_network, ip: ip

      # pull some required Docker images
      config.vm.provision "docker" do |d|
        d.pull_images "docker/ucp"
      end
    end
  end
end
