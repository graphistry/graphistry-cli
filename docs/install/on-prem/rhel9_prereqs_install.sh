#!/bin/bash
set -e 
#set -x 

##############################################################################
#   This script is provided as sample reference only, for installing         #
#     pre-requisites for Graphistry Enterprise Server on an "RHEL 9"         #
#     base image. The process follows loosely the steps                      #
#     taken when we build the underlying base AMIs.                          #
#                                                                            #
#   The script may reboot the machine once, and will need to be run          #
#    a second time to finish the installation.                               # 
#                                                                            #
#                                                                            #
#   Assumptions:                                                             #
#   1. user has sudo rights                                                  #
#   2. User defines GRAPHISTRY_HOME variable prior to running.               #
#      e..g export GRAPHISTRY_HOME=/home/user/graphistry                     #
#                                                                            #
#                                                                            #
#    for assistance:  support@graphistry.com                                 #
#                                                                            #
##############################################################################


[[ ! -z "${GRAPHISTRY_HOME}" ]] \
    || { echo "Set GRAPHISTRY_HOME (ex: /var/graphistry/releases/v2-30-26)" && exit 1; }


########################################
##
## Start: 400-upgrade.sh
##
########################################


sudo dnf clean all
sudo dnf update -y
sudo dnf makecache
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

### AZURE: Breaks repos, so enable
#sudo sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel.repo
#sudo sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-modular.repo

##7:
#sudo dnf clean all
#sudo dnf install -y kernel | grep -q 'already installed' || sudo reboot
#sudo dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
#sudo yum install epel-release


########################################
##
## Start: 510-base-util.sh
##
########################################


sudo dnf install -y \
    htop \
    iftop \
    parallel \
    tree \
    unzip \
    zip  



########################################
##
## Start: 530-nvidia-driver.sh
##
########################################

#8.2
### See links: developer.download.nvida.com/compute/cuda/repos/rhel8/x86_64

sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel9/$(uname -i)/cuda-rhel9.repo
sudo dnf module install -y nvidia-driver:open-dkms

# test nvidia-smi works
nvidia-smi

nvidia-smi


########################################
##
## Start: 532-docker.sh
##
########################################


# Docker 19.03+ for RHEL 8
#  - Note: Podman does not support docker-compose, so we really do want docker, not podman
#  - For available: sudo dnf list docker-ce 

sudo docker --version \
|| {
  sudo dnf config-manager --add-repo=https://download.docker.com/linux/rhel/docker-ce.repo \
  && sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  && sudo systemctl enable docker \
  && sudo systemctl start docker \
  ; \
}


sudo docker --version
sudo docker run --rm hello-world

###nvidia container toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo \
    && sudo dnf clean expire-cache --refresh \
    && sudo dnf install -y nvidia-container-toolkit \
    && nvidia-ctk runtime configure --runtime=docker \
    && systemctl restart docker

#test nvidia container toolkit
sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi

echo Successfully installed all!
