#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

brb -v --triple=i686-unknown-linux-gnu --no-zero-initialized-in-bss --static -O2 "${SCRIPT_DIR}/memory/mem.brc" "${SCRIPT_DIR}/terminal/term.brc"
check
nasm  -f elf32 -o kernel.o "${SCRIPT_DIR}/kernel.asm"
check
ld.lld -T "${SCRIPT_DIR}/kernel.ld" kernel.o mem.o term.o -o kernel.bin