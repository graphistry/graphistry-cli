#!/bin/bash

# Install Docker
sudo apt-get -qq update
sudo apt-get -qq install -y apt-transport-https ca-certificates curl software-properties-common build-essential libffi-dev

sudo apt install -qq -y python-pip python3-pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py
rm get-pip.py