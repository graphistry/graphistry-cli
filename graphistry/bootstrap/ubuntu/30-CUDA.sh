#!/bin/bash

# Install CUDA 9.1 and Dependencies
sudo apt-get -qq install -y linux-headers-$(uname -r)
wget -O cuda.deb https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda-repo-ubuntu1604-9-1-local_9.1.85-1_amd64
sudo dpkg -i cuda.deb
sudo apt-key add /var/cuda-repo-9-1-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -qq install -y cuda
rm cuda.deb