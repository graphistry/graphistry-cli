#!/bin/bash

ensure_command () {
    command -v $1 $2  >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Aborting."; exit 1; }
    echo "--- ✓ [ $1 ]:" `$1 $2`
}

echo "======= " `basename "$0"`

ensure_command docker --version

if sudo docker run hello-world | grep "Hello"
then
    echo "--- ✓ [ docker runs ]"
else
    echo "xxx x docker failed"
    exit 1
fi

