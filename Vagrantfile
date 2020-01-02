# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", run: "always", disabled: false
  config.vm.provision :shell, run: "always" do |shell|
    shell.privileged = true
    shell.path = "./cb_install.sh"
    shell.args = ["-v"]
  end
  config.vm.define "ubuntu16" do |ubuntu16|
    ubuntu16.vm.box = "ubuntu/xenial64"
   end
end
