#!/bin/bash
set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# check if _build/ and doctrees exist
if [ ! -d "${SCRIPT_DIR}/../_build/" ]; then
    echo "Directory _build/ does not exist, nothing to clean"
else
    rm -rf "${SCRIPT_DIR}/../_build/"
fi

if [ ! -d "${SCRIPT_DIR}/../doctrees/" ]; then
    echo "Directory doctrees/ does not exist, nothing to clean"
else
    rm -rf "${SCRIPT_DIR}/../doctrees/"
fi

echo "Cleaned up build artifacts."
