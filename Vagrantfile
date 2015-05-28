# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'
Vagrant.configure("2") do |config|
  config.vm.define "my_docker" # proxy vagrant machine name
  config.vm.provider "docker" do |d|
    d.vagrant_vagrantfile = "./Vagrantfile.boot2docker"
    d.vagrant_machine = "docker_host"
    d.build_dir = "."
    d.build_args = "--tag='yutaf/apache22'"
#    d.image = "yutaf/apache22"
    d.name = "c1"
    # Set "--cap-add=SYS_ADMIN" to enable mounting
    d.create_args = ["--cap-add=SYS_ADMIN","-p","8080:80"]
  end

  # disable default synced_folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  #
  # sync web source
  #

  # nfs
#  config.vm.synced_folder "www/", "/srv/www", type: "nfs"
  # rsync
  config.vm.synced_folder "www/", "/srv/www", type: "rsync", rsync__args: ["-rlpgoDuvcK", "--size-only"],
    rsync__exclude: [
      # exclude permission 777 dirs because git cannot hold dirctory permission and rsync overwrites permissions in guest vm with host permissions that causes application error.
      "www/logs/php_error",
      "www/logs/app",
      # other unnecessary files to rsync
      "README.md",
      "apache.conf",
      "- .*",
      "+ /logs",
      "+ /logs/app",
      "- /logs/app/*",
      "+ /logs/php_error",
      "- /logs/php_error/*",
      "- /logs/*"
  ]
end
