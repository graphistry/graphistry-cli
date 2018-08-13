#!/bin/bash

ensure_command () {
    command -v $1 $2  >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Aborting."; exit 1; }
    echo "--- ✓ [ $1 ]:" `$1 $2`
}

echo "======= " `basename "$0"`

ensure_command "/usr/local/cuda/bin/nvcc" "--version"
ensure_command "nvidia-smi" "-L"

if nvidia-smi -L | grep "GPU 0"
then
    echo "--- ✓ [ has GPU 0]"
else
    echo "xxx x no GPU 0"
    exit 1
fi
