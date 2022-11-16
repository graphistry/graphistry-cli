# Red Hat Enterprise Linux 7.6 (RHEL) manual configuration

For latest test version of scripts, see your Graphistry release's folder `etc/scripts`.

# Warning

We do *not* recommend manually installing the environment dependencies. Instead, use a Graphistry-managed Cloud Marketplace instance, a prebuilt cloud image, or another partner-supplied starting point.

However, sometimes a manual installation is necessary. Use this script as a reference. For more recent versions, check your Graphistry distribution's `etc/scripts` folder, and its links to best practices.

# About

The reference script below was last tested with an AWS RHEL 7.6 2019 AMI on a P3.2 (V100) and Nvidia RAPIDS 0.7. 

* EPEL 7
* Nvidia driver 430.40
* Docker CE 19.03.1
* container-selinux-2.107-1.el7_6.noarch.rpm
* Docker-compose 1.24.1


# Manual RHEL environment configuration

Each subsection ends with a test command. 

```
# Check HW
sudo yum -y install pciutils
lspci | grep -e VGA -ie NVIDIA

# EPEL
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum upgrade kernel
sudo reboot now

# Nvidia Driver
#- https://www.nvidia.com/en-us/drivers/unix/
#=> Latest long-lived branch: 
wget http://us.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run
chmod +x ./NVIDIA-Linux-$(uname -m)-*.run

grep CONFIG_MODULE_SIG=y /boot/config-$(uname -r) && \
grep "CONFIG_MODULE_SIG_FORCE is not set" /boot/config-$(uname -r) && \
sudo ./NVIDIA-Linux-$(uname -m)-*.run -e || \
sudo ./NVIDIA-Linux-$(uname -m)-*.run

nvidia-smi

# Docker
sudo yum install -y yum-utils
sudo yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-1.el7_6.noarch.rpm
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo systemctl enable --now docker

sudo docker run hello-world

# Docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

docker-compose --version

# Nvidia docker runtime
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo |   sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo
sudo yum install -y nvidia-container-runtime
sudo systemctl enable --now docker

sudo docker run --gpus all nvidia/cuda:11.5.0-base-ubuntu20.04 nvidia-smi

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
