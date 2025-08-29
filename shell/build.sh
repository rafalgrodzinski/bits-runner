#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

brb -v --triple=x86_64-unknown-linux-gnu --function-sections "${SCRIPT_DIR}/main.brc" "${SCRIPT_DIR}/terminal.brc"
ld.lld -T "${SCRIPT_DIR}/flat_binary.ld" terminal.o main.o -o shell.bin
