
Vagrant.configure("2") do |config|

  config.vm.define "wp" do |wp|
    wp.vm.box = "ubuntu/jammy64"
    wp.vm.hostname = "wpUbuntu"
    wp.vm.network "forwarded_port", guest: 80, host: 8081
    wp.vm.network "private_network", ip: "192.168.100.2", nic_type: "virtio", virtualbox__intnet: "keepcoding"
    wp.vm.provider "virtualbox" do |vb|
      vb.name = "wordpress"
      vb.gui = false
      vb.memory = "1024"
      vb.cpus = 1
      file_to_disk = "extradisk_wp.vmdk"
      unless File.exist?(file_to_disk)
          vb.customize [ "createmedium", "disk", "--filename", "extradisk_wp.vmdk", "--format", "vmdk", "--size", 1024 * 1 ]
      end
      vb.customize [ "storageattach", "wordpress" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk]
    end
    wp.vm.provision "shell", path: "provision_wp.sh"
  end

  config.vm.define "elk" do |elk|
    elk.vm.box = "ubuntu/jammy64"
    elk.vm.hostname = "elkUbuntu"
    elk.vm.network "forwarded_port", guest: 80, host: 8082
    elk.vm.network "private_network", ip: "192.168.100.3", nic_type: "virtio", virtualbox__intnet: "keepcoding"
    elk.vm.provider "virtualbox" do |vb|
      vb.name = "ELK"
      vb.gui = false
      vb.memory = "4096"
      vb.cpus = 1
      file_to_disk = "extradisk_elk.vmdk"
      unless File.exist?(file_to_disk)
          vb.customize [ "createmedium", "disk", "--filename", "extradisk_elk.vmdk", "--format", "vmdk", "--size", 1024 * 1 ]
      end
      vb.customize [ "storageattach", "ELK" , "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk]
    end
    elk.vm.provision "shell", path: "provision_elk.sh"
  end

end

