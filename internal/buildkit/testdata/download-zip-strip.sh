#!/usr/bin/env bash

set -euo pipefail

export DOWNLOAD_LIBRARY_ONLY=true
source "$1"
STRIP=true
REMOVE=()
unpack "$2" "$3"
