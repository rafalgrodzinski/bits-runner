#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

brb -v --triple=i686-unknown-linux-gnu --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
"${SCRIPT_DIR}/memory/mem.brc" \
"${SCRIPT_DIR}/terminal/term.brc" \
"${SCRIPT_DIR}/filesystem/fs_fat12.brc" \
"${SCRIPT_DIR}/bios_service.brc" \
"${SCRIPT_DIR}/drivers/drv_keyboard.brc" \
"${SCRIPT_DIR}/interrupts/syscall.brc"

check
nasm  -f elf32 -o int.o "${SCRIPT_DIR}/interrupts/int.asm"
check
ld.lld -T "${SCRIPT_DIR}/kernel.ld" main.o term.o mem.o int.o fs_fat12.o bios_service.o drv_keyboard.o syscall.o -o kernel.bin