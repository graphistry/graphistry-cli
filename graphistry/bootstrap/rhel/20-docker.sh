#!/bin/bash

# Install Docker
# https://docs.docker.com/install/linux/docker-ce/centos

sudo yum install -y yum-utils | tee
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo | tee
sudo yum makecache fast | tee

sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2 | tee

sudo yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo | tee

sudo yum -y install docker-ce | tee


sudo groupadd docker
sudo usermod -aG docker $USER

cat >/usr/lib/systemd/system/docker.socket <<EOL
[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOL

sudo systemctl start docker