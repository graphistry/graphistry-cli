# Install Docker
apt-get update
apt-get install -y apt-transport-https     ca-certificates     curl     software-properties-common build-essential libffi-dev
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get -y install docker-ce
usermod -aG docker $USER