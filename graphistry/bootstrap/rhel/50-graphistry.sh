#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f ${DIR}/../../../../deploy/config.json ]; then
    mkdir -p ~/.config/graphistry
    cp ${DIR}/../../../../deploy/config.json ~/.config/graphistry/
    sudo python36 -m wheel install ${DIR}/../../../wheelhouse/* --force
else
    sudo pip3.6 install -r ${DIR}/../../requirements.txt
fi

cd ${DIR}/../../../ && sudo python36 setup.py install
echo -e "\nLogin into a new session to enable docker access, run 'graphistry'.\n"

sudo su - $USER
