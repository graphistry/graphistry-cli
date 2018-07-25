#!/bin/bash

# Install CUDA 9.1 and Dependencies
sudo apt-get -qq install -y linux-headers-$(uname -r)
wget -O cuda.deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
sudo dpkg -i cuda.deb
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo apt-get update
sudo apt-get -qq install -y cuda
rm cuda.deb