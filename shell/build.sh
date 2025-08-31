#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

brb -v --triple=i686-unknown-linux-gnu --function-sections "${SCRIPT_DIR}/main.brc" "${SCRIPT_DIR}/terminal.brc"
if [ $? -ne 0 ]; then
    exit 1
fi
ld.lld -T "${SCRIPT_DIR}/flat_binary.ld" terminal.o main.o -o shell.bin
