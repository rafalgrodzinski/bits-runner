#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

"${SCRIPT_DIR}/memory/build.sh"
check
nasm  -f elf32 -o kernel.o "${SCRIPT_DIR}/kernel.asm"
check
ld.lld -T "${SCRIPT_DIR}/kernel.ld" kernel.o mem.o -o kernel.bin