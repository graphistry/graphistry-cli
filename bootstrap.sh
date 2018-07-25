#!/bin/bash
OS=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo chmod +x ${DIR}/graphistry/bootstrap/$OS/*

if [[ $OS == 'rhel' ]] || [[ $OS == 'ubuntu' ]] || [[ $OS == 'ubuntu-cuda9.2' ]]; then
for SCRIPT in ${DIR}/graphistry/bootstrap/$OS/*
	do
		if [ -f $SCRIPT -a -x $SCRIPT ]
		then
		    echo $SCRIPT
            sleep 1
			$SCRIPT
		fi
	done
else
    echo "Invalid Operating System"
fi
