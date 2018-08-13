#!/bin/bash

ensure_command () {
    command -v $1 $2  >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Aborting."; exit 1; }
    echo "--- ✓ [ $1 ]:" `$1 $2`
}

echo "======= " `basename "$0"`

ensure_command docker --version
ensure_command "/usr/local/cuda/bin/nvcc" "--version"
ensure_command "nvidia-smi" "-L"
ensure_command "docker-compose" "--version"


if sudo docker run hello-world | grep "Hello"
then
    echo "--- ✓ [ docker runs ]"
else
    echo "xxx x docker failed"
    exit 1
fi


if sudo docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi -L | grep "GPU 0"
then
    echo "--- ✓ [ nvidia-docker has GPU 0]"
else
    echo "xxx x nvidia-docker no GPU 0"
    exit 1
fi
