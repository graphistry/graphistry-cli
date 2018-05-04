#!/bin/bash

# Install CUDA 9.1 and Dependencies
sudo yum groupinstall -y "Development Tools" | tee
sudo yum groupinstall -y "Development Libraries" | tee

sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) curl | tee

curl https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda-repo-rhel7-9-1-local-9.1.85-1.x86_64

sudo rpm -i cuda-repo-rhel7-9-1-local-9.1.85-1.x86_64 | tee
sudo yum clean all | tee
sudo yum install cuda | tee