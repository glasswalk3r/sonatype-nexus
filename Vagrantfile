# frozen_string_literal: true

require 'json'

def read_manifest
  file = File.open('config/manifest.json')
  from_to = JSON.parse(file.read)
  file.close
  from_to
end

Vagrant.configure('2') do |config|
  config.vm.box = 'generic/rocky8'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = true
  config.vm.network 'forwarded_port', guest: 8081, host: 9090,
                                      host_ip: '127.0.0.1',
                                      id: 'nexus'

  config.vbguest.auto_update = false
  config.vm.provider 'virtualbox' do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
    # Customize the amount of memory on the VM:
    vb.memory = '4096'
    vb.cpus = 2
    vb.customize ['modifyvm', :id, '--vram', 9]
    vb.customize ['modifyvm', :id, '--uartmode1', 'disconnected']
    vb.customize ['modifyvm', :id, '--vrde', 'off']
    vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
    vb.customize ['modifyvm', :id, '--audio', 'none']
    vb.name = 'Nexus OSS 3'
  end

  config.vm.provision 'shell', inline: 'dnf update -y && dnf install ansible -y'
  playbooks_dir = './playbooks'

  config.vm.provision 'ansible' do |ans|
    ans.playbook = "#{playbooks_dir}/packages.yml"
    ans.compatibility_mode = '2.0'
  end

  # here we apply the role
  config.vm.provision 'ansible' do |ans|
    ans.playbook = "#{playbooks_dir}/hardening.yml"
  end

  from_to = read_manifest
  from_to.each do |file|
    config.vm.provision 'file', source: "config/#{file['name']}", destination: "/tmp/#{file['name']}"
    config.vm.provision 'shell', inline: "mv -v /tmp/#{file['name']} #{file['to']}/#{file['name']}
    chown root.root #{file['to']}/#{file['name']}"
  end

  scripts = ['basic.sh']
  scripts.each { |file| config.vm.provision 'shell', path: "scripts/#{file}" }
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
