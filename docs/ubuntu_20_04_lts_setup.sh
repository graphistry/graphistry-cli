#!/bin/bash

set -ex 

##############################################################################
#   This is a sample script that can be used to install pre-requisites for   #
#    Graphistry Enterprise Server on an "ubuntu 20.04 LTS" base image.       #
#                                                                            #
#   The script will reboot the machine once, and will need to be run         #
#    a second time to finish the installation. It uses a breadcrumb          #
#    file to know whether the first portion has been run or not.             #
#                                                                            #
#    To run the script again from the beginning, delete the                  #
#    file: /tmp/g-part1.lck                                                  #
#                                                                            #
#    for assistance:  support@graphistry.com                                 #
#                                                                            #
##############################################################################

lock_file=/tmp/g-part1.lck

if [ ! -f ${lock_file} ]; then 

	###################
	#                 #
	#   update base   #
	#                 #
	###################

	sudo apt update
	sudo apt upgrade -y 


	###################
	#                 #
	#  Nvidia driver  #
	#                 #
	###################


	sudo add-apt-repository -y ppa:graphics-drivers/ppa
	sudo apt-get update
	sudo apt install -y nvidia-driver-470

	touch ${lock_file}

	sudo reboot
fi

echo "start stage 2 graphistry pre-reqs..."; echo 

nvidia-smi


#####################
#                   #
#  Docker 23.0.1    #
#                   #
#####################


sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo DEBIAN_FRONTEND=noninteractive apt-get update
echo "Available: " && sudo apt-cache madison docker-ce
echo "Available: " && sudo apt-cache madison docker-ce-cli
echo "Available: " && sudo apt-cache madison containerd.io

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            docker-ce=5:23.0.1-1~ubuntu.20.04~focal \
            docker-ce-cli=5:23.0.1-1~ubuntu.20.04~focal \
            containerd.io=1.6.16-1 \
            docker-buildx-plugin \
            docker-compose-plugin

echo 'options overlay metacopy=off redirect_dir=off' | sudo tee -a /etc/modprobe.d/disable_overlay_redirect_dir.conf
sudo modprobe -r overlay && sudo modprobe overlay  && { sudo systemctl start docker && sudo systemctl enable docker ; }

sudo docker --version
sudo docker info
sudo docker run --rm hello-world
sudo docker info | grep "Native Overlay Diff" | grep "true" || echo "WARNING: Native Overlay Diff is not true"
sudo docker compose version

sudo usermod -aG docker $USER


####################
#                  #
#  nvidia runtime  #
#                  #
####################

#NVIDIA_CONTAINER="nvidia/cuda:11.0.3-base-ubuntu18.04"
#  which one is best to test? 
NVIDIA_CONTAINER="nvidia/cuda:11.4.0-base-ubuntu20.04"

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

sudo systemctl restart docker

# test run with nvidia runtime as param 
sudo docker run --gpus all ${NVIDIA_CONTAINER} nvidia-smi

###########################
#                         #
#  nvidia default runtime #
#                         #
###########################

# set nvidia as default runtime (needed for docker compose)

cat << EOF > ~/tmp_daemon.json
{
    "default-runtime": "nvidia",
    "live-restore": true,
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

sudo mkdir -p /etc/docker
sudo mv -f ~/tmp_daemon.json /etc/docker/daemon.json

sudo systemctl restart docker

###########################
#                         #
#  test configuration     #
#                         #
###########################

# test run with nvidia runtime as param 
sudo docker run --runtime=nvidia --rm ${NVIDIA_CONTAINER} nvidia-smi

# test nvidia runtime set as default (from /etc/docker/daemon.json above) 
sudo docker run --rm ${NVIDIA_CONTAINER}  nvidia-smi

