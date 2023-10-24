#!/bin/bash
set -e 
#set -x 

##############################################################################
#   This script is provided as sample reference only, for installing         #
#     pre-requisites for Graphistry Enterprise Server on an "RHEL 8"         #
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
sudo dnf install -y kernel | grep -q 'Nothing to do' || sudo reboot
sudo dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

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
## Start: 520-base-python.sh
##
########################################


python2.7 --version || sudo dnf install -y python27
python2.7 --version

python3.6 --version || sudo dnf install -y python36
python3.6 --version


########################################
##
## Start: 530-nvidia-driver.sh
##
########################################

#8.2
### See links: developer.download.nvida.com/compute/cuda/repos/rhel8/x86_64

wget https://download.nvidia.com/XFree86/Linux-x86_64/470.199.02/NVIDIA-Linux-x86_64-470.199.02.run

sudo yum groupinstall -y "Development Tools"
sudo yum install -y kernel-devel epel-release
sudo yum install -y dkms

# install driver
sudo sh NVIDIA-Linux-x86_64-470.199.02.run --no-questions --ui=none
# check driver install
sudo sh NVIDIA-Linux-x86_64-470.199.02.run --sanity --no-questions --ui=none

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
  sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo \
  && sudo dnf install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.3.7-3.1.el7.x86_64.rpm \
  && sudo dnf install docker-ce-3:19.03.13-3.el8 -y \
  && sudo systemctl enable docker \
  && sudo systemctl start docker \
  ; \
}
### AZURE: Breaks repos, so do after sudo dnf config-manager / before dnf install
#sudo sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo

sudo docker --version
sudo docker run --rm hello-world


########################################
##
## Start: 533-docker-compose.sh
##
########################################


docker compose version \
|| { \
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker compose$(uname -s)-$(uname -m)" -o /usr/local/bin/docker compose \
    && { sudo chmod +x /usr/local/bin/docker compose ; } \
    && { \
        sudo curl \
            -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker compose \
            -o /etc/bash_completion.d/docker compose \
    ; } \
    && { sudo docker compose version || sudo ln -s /usr/local/bin/docker compose /usr/bin/docker compose ; } \
    && { sudo docker compose version ; } \
; }

########################################
##
## Start: 534-nvidia-docker.sh
##
########################################


[[ ! -z "${GRAPHISTRY_HOME}" ]] \
    || { echo "Set GRAPHISTRY_HOME (ex: /var/graphistry/releases/v2-30-26)" && exit 1; }

BOOTSTRAP_DIR="${GRAPHISTRY_HOME}/etc/scripts/bootstrap"
CUDA_SHORT_VERSION=${CUDA_SHORT_VERSION:-`cat ${GRAPHISTRY_HOME}/CUDA_SHORT_VERSION`}
NVIDIA_CONTAINER="nvidia/cuda:11.5.2-base-ubuntu20.04"


sudo docker run --rm --gpus all ${NVIDIA_CONTAINER} nvidia-smi \
|| { \
    { \
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
       && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo \
       | sudo tee /etc/yum.repos.d/nvidia-docker.repo \
       ; \
    } \
    && sudo dnf clean expire-cache --refresh \
    && sudo dnf install -y nvidia-docker2 \
    && { sudo systemctl restart docker ; } \
    ; \
}


sudo docker run --rm --gpus all ${NVIDIA_CONTAINER} nvidia-smi

sudo docker run --rm ${NVIDIA_CONTAINER} nvidia-smi \
|| { \
    { sudo mv ${BOOTSTRAP_DIR}/assests/etc-docker-daemon.json /etc/docker/daemon.json ; } \
    && { sudo systemctl restart docker ; } \
    && { sudo docker run --rm --runtime nvidia ${NVIDIA_CONTAINER} nvidia-smi ; } \
    ; \
}

sudo docker run --rm ${NVIDIA_CONTAINER} nvidia-smi

echo Successfully installed all!
