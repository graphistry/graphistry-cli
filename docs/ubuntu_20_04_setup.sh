#!/bin/bash
set -ex

##############################################################################
#   This script is provided as sample reference only, for installing         #
#     pre-requisites for Graphistry Enterprise Server on an "Ubuntu 20.04    #
#     LTS" base image running in AWS. The process follows loosely the steps  #
#     taken when we build the underlying base AMIs.                          #
#                                                                            #
#   The script will reboot the machine once, and will need to be run         #
#    a second time to finish the installation. It uses a breadcrumb          #
#    file to know whether the first portion has been run or not.             #
#                                                                            #
#    To run the script again from the beginning, delete the                  #
#    file: ~/g-part1.lck                                                     #
#                                                                            #
#   Assumptions:                                                             #
#   1. the user running this script is the ubuntu user                       #
#   2. user has sudo rights                                                  #
#   3. graphistry software is unpacked into `/home/ubuntu/graphistry`        #
#                                                                            #
#                                                                            #
#    for assistance:  support@graphistry.com                                 #
#                                                                            #
##############################################################################

lock_file=~/g-part1.lck

if [ ! -f ${lock_file} ]; then

    # 100-verify.sh:

    # 100-verify.sh skipped - not needed for this install method

    # 200-reset.sh

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--            ubuntu_disable_init.sh         --"
    echo "--                                           --"
    echo "-----------------------------------------------"

    echo "----- CHECK APT -------"
    ps -aux | grep apt || echo ok

    echo "---- DISABLE apt-daily ----"
    ### https://stackoverflow.com/questions/45269225/ansible-playbook-fails-to-lock-apt/51919678#51919678
    sudo systemctl disable --now 'apt-daily.timer'
    sudo systemctl disable --now 'apt-daily-upgrade.timer'
    sudo systemctl daemon-reload
    sudo systemctl stop snapd.service || echo 'failed to stop snapd'
    sudo systemctl disable snapd.service || echo 'failed to disable snapd'

    # Syncing time is only relevant for testing, because of the VM's outdated date.
    #- name: Sync time
    #  raw: date -s "{{ lookup('pipe', 'date') }}"
    sudo systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
    sudo apt-get -y purge unattended-upgrades \
    || {
        echo "Purge failed, retry" \
        && echo "----- CHECK APT2 -------" \
        && { ps -aux | grep apt || echo ok ; } \
        && echo "----- Purge2 -----------" \
        && sudo apt-get -y purge unattended-upgrades \
        ; \
    }

    echo "---- DISABLE apt periodic ----"
    #https://askubuntu.com/questions/1006189/how-to-stop-apt-from-doing-anything
    echo 'APT::Periodic::Enable "0";' | \
    sudo tee /etc/apt/apt.conf.d/99periodic-disable

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--        done ubuntu_disable_init.sh        --"
    echo "--                                           --"
    echo "-----------------------------------------------"


    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--            fix_hosts.sh                   --"
    echo "--                                           --"
    echo "-----------------------------------------------"

    ip=$(ip route get 1 | awk '{print $NF;exit}')
    hostname=$(hostname)
    complete="127.0.0.1 localhost
    ${ip} ${hostname}
    # The following lines are desirable for IPv6 capable hosts
    ::1 ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    ff02::3 ip6-allhosts"
    echo "$complete" | sudo tee /etc/hosts


    echo "----- old dns -----------"
    cat /etc/resolv.conf

    echo "----- add google dns ----"
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
    echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--        done fix_hosts.sh                  --"
    echo "--                                           --"
    echo "-----------------------------------------------"


    sudo systemctl stop snapd.service || echo 'failed to stop snapd'
    sudo systemctl disable snapd.service || echo 'failed to disable snapd'


    # 300-populate.sh:

    cat << EOF > ~/tmp_00-header
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (C) 2009-2010 Canonical Ltd.
#
#    Authors: Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi


printf "=============================================================================\n"
printf "                                                                             \n"
printf " ______  ______ _______  _____  _     _ _____ _______ _______  ______ __   __\n"
printf "|  ____ |_____/ |_____| |_____] |_____|   |   |______    |    |_____/   \_/  \n"
printf "|_____| |    \_ |     | |       |     | __|__ ______|    |    |    \_    |   \n"
printf "                                                                             \n"
printf "                                                                             \n"
printf "=============================================================================\n"
#printf "  Graphistry %s\n" "$(source /home/ubuntu/graphistry/.env && echo $APP_BUILD_TAG)"
#printf "=============================================================================\n"
printf "\n"
printf " * Graphistry: ~/graphistry\n"
printf " * Main docs: http://localhost/docs and hub.graphistry.com/docs\n"
printf " * Admin docs: ~/graphistry/docs and https://github.com/graphistry/graphistry-cli\n"
printf " * Support: https://graphistry.zendesk.com\n"
printf " * Private dedicated Slack channel: Contact your support staff\n"
printf "\n"
printf "=============================================================================\n"
EOF


    sudo mv ~/tmp_00-header /etc/update-motd.d/00-header
    sudo chmod 755 /etc/update-motd.d/00-header


    cat << EOF > ~/tmp_graphistry-compose.service
[Unit]
Description=make graphistry creds once, then run via docker-compose
After=docker.service sockets.target
BindsTo=docker.service sockets.target
ReloadPropagatedFrom=docker.service

[Service]
Type=exec
User=ubuntu
ExecStart=/bin/sh -c 'cd /home/ubuntu/graphistry && ( grep SECRET_KEY ./data/config/custom.env || ./etc/scripts/cred-gen.sh >> ./data/config/custom.env; ) && { sudo docker compose up || { sleep 20 && sudo COMPOSE_HTTP_TIMEOUT=180 docker compose up; }; }'
ExecStop=/bin/sh -c 'cd /home/ubuntu/graphistry && sudo docker compose down'

[Install]
WantedBy=multi-user.target
EOF

    sudo mv ~/tmp_graphistry-compose.service /etc/systemd/system/graphistry-compose.service
    sudo systemctl enable graphistry-compose.service


    # 400-upgrade.sh:

    DEBIAN_FRONTEND=noninteractive sudo apt-get update \
        && echo "======= UPDATED SUCCESSFULLY =======" \
        || echo "======= UPDATE FAILED ======="

    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade \
        && echo "======= UPGRADED SUCCESSFULLY ======" \
        || echo "======= UPGRADE FAILED ======"

    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y build-essential ca-certificates \
        && echo "======  INSTALLED SUCCESSFULY =======" \
        || echo "======  INSTALL FAILED ======="


    # 510-base-util.sh:

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        htop \
        iftop \
        lsb-release \
        parallel \
        tree \
        unzip \
        zip

    # 520-base-python.sh:

    echo "Python defaults to 2.7 for node-gyp and provide 3.8 for everyone else"
    python3.8 --version && python2.7 --version  \
    || {
        { sudo add-apt-repository -y ppa:ubuntu-toolchain-r/ppa ; } \
        && { DEBIAN_FRONTEND=noninteractive sudo apt install -y python3.8 python2.7 python3-pip ; } \
        ;
    }

    # 530-nvidia-driver.sh:

    nvidia-smi \
    || {
        { sudo add-apt-repository -y ppa:graphics-drivers/ppa && sudo apt-get update ; } \
        && { sudo apt-get install -y nvidia-driver-470 ; } \
    ; }

    touch ${lock_file}

    echo
    echo "WARNING: rebooting in 30 seconds, hit CTRL-C to cancel"
    echo
    sleep 30

    sudo reboot

fi

echo "starting stage 2 graphistry pre-reqs..."; echo

# 532-docker.sh:

sudo docker --version \
|| { \
    { \
        sudo mkdir -m 0755 -p /etc/apt/keyrings \
        && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg ; \
    } \
    && { \
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null ; \
    } \
    && { sudo DEBIAN_FRONTEND=noninteractive apt-get update ; } \
    && { echo "Available: " && sudo apt-cache madison docker-ce ; } \
    && { echo "Available: " && sudo apt-cache madison docker-ce-cli ; } \
    && { echo "Available: " && sudo apt-cache madison containerd.io ; } \
    && { \
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            docker-ce=5:23.0.1-1~ubuntu.20.04~focal \
            docker-ce-cli=5:23.0.1-1~ubuntu.20.04~focal \
            containerd.io=1.6.16-1 \
            docker-buildx-plugin \
            docker-compose-plugin \
    ; } \
    && { \
        { echo 'options overlay metacopy=off redirect_dir=off' | sudo tee -a /etc/modprobe.d/disable_overlay_redirect_dir.conf ; } \
        && sudo modprobe -r overlay \
        && sudo modprobe overlay \
    ; } \
    && { sudo systemctl start docker && sudo systemctl enable docker ; } \
; }

sudo docker --version
sudo docker info
sudo docker run --rm hello-world
sudo docker info | grep "Native Overlay Diff" | grep "true" || echo "WARNING: Native Overlay Diff is not true"
sudo docker compose version

# 534-nvidia-docker.sh:

# not used:
# CUDA_SHORT_VERSION=${CUDA_SHORT_VERSION:-`cat ${GRAPHISTRY_HOME}/CUDA_SHORT_VERSION`}
NVIDIA_CONTAINER="docker.io/rapidsai/base:24.04-cuda11.8-py3.10"


sudo docker run --rm --gpus all ${NVIDIA_CONTAINER} nvidia-smi \
|| { \
    { curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | sudo apt-key add - && sudo apt update ; } \
    && { distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list && sudo apt-get update ; } \
    && { sudo apt-get install -y nvidia-container-runtime ; } \
    && { curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - ; } \
    && { distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list && sudo apt-get update ; } \
    && { sudo apt-get install -y nvidia-container-toolkit ; } \
    && { sudo systemctl restart docker ; } \
    && { sudo docker run --rm --gpus all ${NVIDIA_CONTAINER} nvidia-smi ; } \
    ; \
}

# set nvidia as default runtime (needed for docker compose)

cat << EOF > ~/tmp_etc-docker-daemon.json
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

sudo docker run --rm ${NVIDIA_CONTAINER} nvidia-smi \
|| { \
    { sudo mv ~/tmp_etc-docker-daemon.json /etc/docker/daemon.json ; } \
    && { sudo systemctl restart docker ; } \
    && { sudo docker run --rm --runtime nvidia ${NVIDIA_CONTAINER} nvidia-smi ; } \
    ; \
}

sudo docker run --rm ${NVIDIA_CONTAINER} nvidia-smi

echo "Successfully installed all!"
