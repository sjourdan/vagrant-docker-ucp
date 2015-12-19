# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

# defaults if not set in config.rb
$vm_box = "ubuntu/trusty64"
$ucp_master_memory = "2048"
$ucp_slave_memory = "2048"
$ucp_master_ip = "192.168.10.10"
$ucp_slave_ip = "192.168.10.11"

CONFIG = File.join(File.dirname(__FILE__), "config.rb")

if File.exist?(CONFIG)
  require CONFIG
end

%w(vagrant-cachier).each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "#{plugin} plugin is not installed! Please install it using `vagrant plugin install #{plugin}`"
  end
end

Vagrant.configure(2) do |config|
  config.vm.provision "shell", inline: "echo BOOTSTRAPPING UCP DEMO"

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

  config.vm.define "ucp-master", primary: true do |master|
    master.vm.box = $vm_box

    master.vm.provider "virtualbox" do |vb|
      vb.memory = $ucp_master_memory
    end

    master.vm.network "private_network", ip: $ucp_master_ip

    master.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y linux-virtual-lts-wily linux-image-extra-virtual-lts-wily
      sudo curl -sSL https://get.docker.com/ | sh
      sudo usermod -aG docker vagrant
      sudo apt-get autoremove -y
    SHELL

    # pull some required Docker images
    master.vm.provision "docker" do |d|
      d.pull_images "dockerorca/ucp"
      d.pull_images "swarm"
    end

  end

  config.vm.define "ucp-slave" do |slave|
    slave.vm.box = $vm_box

    slave.vm.provider "virtualbox" do |vb|
      vb.memory = $ucp_slave_memory
    end

    slave.vm.network "private_network", ip: $ucp_slave_ip

    slave.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y linux-virtual-lts-wily linux-image-extra-virtual-lts-wily
      sudo curl -sSL https://get.docker.com/ | sh
      sudo usermod -aG docker vagrant
      sudo apt-get autoremove -y
    SHELL

    # pull some required Docker images
    slave.vm.provision "docker" do |d|
      d.pull_images "dockerorca/ucp"
      d.pull_images "swarm"
    end

  end

end
