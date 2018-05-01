#!/bin/bash

# https://github.com/NVIDIA/nvidia-docker
# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker-1.0.1-1.x86_64.rpm
sudo rpm -i /tmp/nvidia-docker*.rpm && rm /tmp/nvidia-docker*.rpm
sudo systemctl start nvidia-docker