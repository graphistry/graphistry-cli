#!/bin/bash

if [ -f deploy/config.json ]; then
    mkdir -p .config/graphistry
    cp deploy/config.json .config/graphistry/
    sudo python36 -m wheel install graphistry-cli/wheelhouse/* --force
else
    sudo pip3.6 install -r graphistry-cli/graphistry/requirements.txt
fi

if [ -d "graphistry-cli" ]; then

    cd graphistry-cli && sudo python36 setup.py install
    echo -e "\nLoggin into a new session to enable docker access, run 'graphistry'.\n"

    sudo su - $USER
fi