#!/bin/bash
OS=$1

chmod +x graphistry/bootstrap/$OS/*

if [$OS = 'rhel' || $OS = 'ubuntu']; then
for SCRIPT in graphistry/bootstrap/$OS/*
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