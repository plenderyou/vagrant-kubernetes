# -*- mode: ruby -*-
# vi: set ft=ruby :
require_relative 'customise'

Vagrant.configure("2") do |config|


  (0..NODES).each do |i|
    masterNodeName = CLUSTER_PREFIX + "master"
    if i == 0
      name=CLUSTER_PREFIX + "master"
      memory=MASTER_MEMORY
    else
      name=CLUSTER_PREFIX + "node-#{i}"
      memory=NODE_MEMORY
    end

    ip = IP_BASE + ".1#{i}"
    config.vm.define "#{name}" do |node|
      node.vm.box = "ubuntu/xenial64"
      node.vm.hostname = "#{name}"
      node.vm.network "private_network", ip: "#{ip}"
      node.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        # vb.gui = true
          # Customize the amount of memory on the VM:
        vb.memory = "#{memory}"
        vb.name = "#{name}-xenial-64"
      end



      if i == NODES

        node.vm.provision "ansible" do |ansible|
            ansible.playbook = "setup.yml"
            ansible.sudo = true
            #ansible.extra_vars = { "LOCAL_IP" => ENV['HOSTNAME'], "username" => ENV['USER'], "ansible_python_interpreter" => "/usr/bin/python2.7", "ipaddress" => "#{ip}" }
            ansible.verbose = "v"
            ansible.limit = "all"
        end

        node.vm.provision "ansible" do |ansible|
            ansible.playbook = "provision.yml"
            ansible.sudo = true
            ansible.extra_vars = { "LOCAL_IP" => ENV['HOSTNAME'], "username" => ENV['USER'], "ansible_python_interpreter" => "/usr/bin/python2.7", "masterNodeName" => "#{masterNodeName}" }
            ansible.verbose = "v"
            ansible.limit = "all"
        end

      end
    end
  end

end
