#!/bin/bash

# Install Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https     ca-certificates     curl     software-properties-common build-essential libffi-dev
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get -y install docker-ce
sudo usermod -aG docker $USER

# Install Nvidia Drivers
lspci | grep -i nvidia
gcc --version

sudo apt-get install -y linux-headers-$(uname -r)
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo dpkg -i cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
sudo apt-get update
sudo apt-get install -y cuda

# Install Nvidia Docker
# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

# Test nvidia-smi
. ~/.profile
nvidia-docker run --rm nvidia/cuda nvidia-smi

sudo apt install -y python-pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py
rm get-pip.py

sudo pip install pip --upgrade
sudo pip3 install nvidia-docker-compose

## Install Node 9
#curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
#sudo apt-get install -y nodejs
#$sudo npm install bcrypt-cli -g

sudo pip3 install fabric3 jinja2 requests bcrypt
