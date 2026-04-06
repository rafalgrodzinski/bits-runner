#!/bin/bash

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
BRC_LIB="`brew --prefix`/lib/brc"
SYS_DIR="${SCRIPT_DIR}/../.."

brb --verb=v2 --opt=o2 --triple=i686-unknown-linux-gnu --function-sections --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
"${BRC_LIB}/B/String.brc" \
"${SYS_DIR}/lib/B/BSys.brc" \
"${SYS_DIR}/lib/Sys/Syscall.brc" \
"${SYS_DIR}/kernel/Intrinsics.brc"
check

ld.lld -T "${SCRIPT_DIR}/app.ld" -o vdemo.bin \
main.o \
B.o \
BSys.o \
Syscall.o
check