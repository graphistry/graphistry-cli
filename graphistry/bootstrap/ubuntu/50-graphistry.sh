#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f ${DIR}/../../../../deploy/config.json ]; then
    mkdir -p ~/.config/graphistry
    cp ${DIR}/../../../../deploy/config.json ~/.config/graphistry/
    sudo python3 -m wheel install ${DIR}/../../../wheelhouse/* --force
else
    sudo pip3 install -r ${DIR}/../../requirements.txt
fi

cd ${DIR}/../../../ && sudo python3 setup.py install
echo -e "\nLoggin into a new session to enable docker access, run 'graphistry'.\n"

sudo su - $USER