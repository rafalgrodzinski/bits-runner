#!/bin/bash

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
BRB_DIR="$(dirname "$(which brb)")/.."
SYS_DIR="${SCRIPT_DIR}/.."

brb --verb=v2 --triple=i686-unknown-linux-gnu --function-sections --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
"${BRB_DIR}/lib/B/String.brc" \
"${SYS_DIR}/lib/B/BSys.brc" \
"${SYS_DIR}/lib/B/BStdLib.brc" \
"${SYS_DIR}/lib/Sys/Syscall.brc" \
&&

ld.lld -T "${SCRIPT_DIR}/shell.ld" -o shell.bin \
main.o \
B.o \
BSys.o \
Syscall.o \

check
