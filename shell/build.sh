#!/bin/bash

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

brb -v --triple=i686-unknown-linux-gnu --function-sections -O0 "${SCRIPT_DIR}/main.brc" "${SCRIPT_DIR}/terminal.brc" "${SCRIPT_DIR}/sys.brc"
check
ld.lld -T "${SCRIPT_DIR}/flat_binary.ld" terminal.o main.o sys.o -o shell.bin
check
