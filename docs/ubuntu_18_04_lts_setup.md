# Ubuntu 18.04 LTS manual configuration

For latest test version of scripts, see your Graphistry release's folder `etc/scripts`.

# Warning

We do *not* recommend manually installing the environment dependencies. Instead, use a Graphistry-managed Cloud Marketplace instance, a prebuilt cloud image, or another partner-supplied starting point.

However, sometimes a manual installation is necessary. Use this script as a reference. For more recent versions, check your Graphistry distribution's `etc/scripts` folder, and its links to best practices.

# About

The reference script below was last tested with an Azure Ubuntu 18.04 LTS  AMI on NC series. 


* Nvidia driver 430.26
* CUDA 10.2 (NOTE: 11.0 now required for RAPIDS 2022.x, or 11.5+ for Graphistry AI extensions)
* Docker CE 19.03.1
* docker-compose 1.24.1
* nvidia-container 1.0.4


# Manual environment configuration

Each subsection ends with a test command. 

```
###################
#                 #
#   <3 <3 <3 <3   #
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
sudo apt install -y nvidia-driver-430

sudo reboot

nvidia-smi


###################
#                 #
#  Docker 19.03+  #
#                 #
###################

#apt is 18, so go official
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt install -y docker-ce=5:19.03.1~3-0~ubuntu-bionic

sudo systemctl start docker
sudo systemctl enable docker

sudo docker --version
sudo docker run hello-world

####################
#                  #
#  docker-compose  #
#                  #
####################

sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version


####################
#                  #
#  nvidia runtime  #
#                  #
####################

### Sometimes needed
#curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | sudo apt-key add - && sudo apt update
#distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list && sudo apt-get update
#sudo apt-get install -y nvidia-container-runtime

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && echo $distribution
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

#_not_ default runtime
sudo docker run --gpus all nvidia/cuda:11.5.0-base-ubuntu20.04 nvidia-smi

####################
#                  #
#  nvidia default  #
#                  #
####################

# Nvidia docker as default runtime (needed for docker-compose)
sudo yum install -y vim
sudo vim /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
sudo systemctl restart docker

sudo docker run --runtime=nvidia --rm nvidia/cuda:11.5.0-base-ubuntu20.04 nvidia-smi
sudo docker run --rm nvidia/cuda:11.5.0-base-ubuntu20.04 nvidia-smi
```
