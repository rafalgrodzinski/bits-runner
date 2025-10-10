#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

brb -v --triple=i686-unknown-linux-gnu --function-sections -O2 "${SCRIPT_DIR}/mem.brc"
check
