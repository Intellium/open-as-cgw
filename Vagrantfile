# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Set a hostname for the new box
  # this should be a fully-qualified domain name
  config.vm.hostname = "antispam.local"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 22, host: 22
  config.vm.network "forwarded_port", guest: 25, host: 25
  config.vm.network "forwarded_port", guest: 587, host: 587
  config.vm.network "forwarded_port", guest: 443, host: 443

  # Create a private network, which allows host-only 
  # access to the machine using a specific IP.
  config.vm.network "private_network", ip: "192.168.200.100"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell" do |s|
    s.path = "https://raw.githubusercontent.com/open-as-team/ovf-builder/master/scripts/install.sh"
    s.args = "--yes"
  end
end
