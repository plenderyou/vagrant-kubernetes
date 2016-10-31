# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  ipBase = "172.16.99"
  nodes = 3


  (0..nodes).each do |i|
    if i == 0
      name="tmaster"
    else
      name="tnode-#{i}"
    end

    ip = "#{ipBase}.1#{i}"
    config.vm.define "#{name}" do |node|
      node.vm.box = "ubuntu/xenial64"
      node.vm.hostname = "#{name}"
      node.vm.network "private_network", ip: "#{ip}"
      node.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        # vb.gui = true
          # Customize the amount of memory on the VM:
        vb.memory = "1024"
        vb.name = "t#{name}-xenial-64"
      end



      if i == nodes

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
            ansible.extra_vars = { "LOCAL_IP" => ENV['HOSTNAME'], "username" => ENV['USER'], "ansible_python_interpreter" => "/usr/bin/python2.7", "ipaddress" => "#{ip}" }
            ansible.verbose = "v"
            ansible.limit = "all"
        end

      end
    end
  end

end
