#!/bin/bash

if [ -f ${PWD}/../deploy/config.json ]; then
    mkdir -p ~/.config/graphistry
    cp ${PWD}/../deploy/config.json ~/.config/graphistry/
    sudo python3 -m wheel install ${PWD}/wheelhouse/* --force
else
    sudo pip3 install -r ${PWD}/graphistry/requirements.txt
fi

sudo python36 setup.py install
echo -e "\nLoggin into a new session to enable docker access, run 'graphistry'.\n"

sudo su - $USER