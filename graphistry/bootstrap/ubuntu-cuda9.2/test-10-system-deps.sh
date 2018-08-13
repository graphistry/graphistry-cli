#!/bin/bash

ensure_command () {
    command -v $1 $2  >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Aborting."; exit 1; }
    echo "--- ✓ [ $1 ]:" `$1 $2`
}


echo "======= " `basename "$0"`

ensure_command curl --version
ensure_command pip3 --version

