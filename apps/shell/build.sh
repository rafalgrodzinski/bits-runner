#!/bin/bash

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
PREFIX="${PREFIX:-`brew --prefix`}"
PATH="${PREFIX}/bin:${PREFIX}/build:${PATH}"
BLIB="${PREFIX}/lib/brc/B"
LIB="${SCRIPT_DIR}/../lib"

brb --verb=v2 --opt=o2 --triple=i686-unknown-linux-gnu --function-sections --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
"${BLIB}/String.brc" \
"${LIB}/BSys.brc" \
"${LIB}/Syscall.brc" \
"${LIB}/Intrinsics.brc"
check

ld.lld -T "${SCRIPT_DIR}/app.ld" -o shell.bin \
main.o \
B.o \
BSys.o \
Syscall.o
check
