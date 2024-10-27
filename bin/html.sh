#!/bin/bash
set -ex

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ci_file="$script_dir/ci.html"

DOCS_FORMAT=html "${SCRIPT_DIR}/ci.sh"
