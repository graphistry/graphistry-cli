#!/bin/bash
sudo yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.42-1.gitad8f0f7.el7.noarch.rpm | tee
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm | tee

sudo yum install -y wget sudo python36 python36-devel | tee
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python36 get-pip.py
rm get-pip.py