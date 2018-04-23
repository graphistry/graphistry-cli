# Show system data
cat /etc/*-release

sudo yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.42-1.gitad8f0f7.el7.noarch.rpm | tee
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm | tee

sudo yum install -y wget sudo python34 python34-pip | tee

# Install Docker
# https://docs.docker.com/install/linux/docker-ce/centos

sudo yum install -y yum-utils | tee
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo | tee
sudo yum makecache fast | tee

sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2 | tee

sudo yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo | tee

sudo yum -y install docker-ce | tee


sudo groupadd docker
sudo usermod -aG docker $USER

cat >/usr/lib/systemd/system/docker.socket <<EOL
[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOL

sudo systemctl start docker

# Install CUDA 9.1 and Dependencies
sudo yum groupinstall -y "Development Tools" | tee
sudo yum groupinstall -y "Development Libraries" | tee

sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) | tee

function checkmd5() {
  md5_to_test=$1
  md5_from_file=$(md5sum "$2" | cut -d " " -f1)
  md5_results="Input: $md5_to_test\nFile:  $md5_from_file"
  if [[ $md5_to_test == $md5_from_file ]]
    then
      echo -e "\n\e[92mMD5 SUCCESS\e[39m\n$md5_results"
    else
      echo -e "\n\e[91mMD5 FAILURE\e[39m\n$md5_results"
      exit
  fi
}

CUDA_MD5=275932fb004e8344963c7ed96a28fd44
curl http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.1.85-1.x86_64.rpm -o cuda.rpm

checkmd5 $CUDA_MD5 cuda.rpm
sudo rpm -i cuda.rpm | tee
rm cuda.rpm
sudo yum install -y cuda | tee


# https://github.com/NVIDIA/nvidia-docker
# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker-1.0.1-1.x86_64.rpm
sudo rpm -i /tmp/nvidia-docker*.rpm && rm /tmp/nvidia-docker*.rpm
sudo systemctl start nvidia-docker

echo "Test Nvidia-Docker Install"
#sudo su - $USER exit
#nvidia-docker run --rm nvidia/cuda nvidia-smi

sudo pip3 install fabric3 jinja2 requests bcrypt git+https://github.com/jonathanslenders/python-prompt-toolkit.git@2.0

echo "Please log out and back in to use docker, then run graphistry"

