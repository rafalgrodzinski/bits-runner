#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

brb --verb=v2 --function-sections --triple=i686-unknown-linux-gnu --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
"${SCRIPT_DIR}/memory/mem.brc" \
"${SCRIPT_DIR}/terminal/term.brc" \
"${SCRIPT_DIR}/drivers/drv_keyboard.brc" \
"${SCRIPT_DIR}/BiosService.brc" \
\
"${SCRIPT_DIR}/Int/IntHandler.brc" \
"${SCRIPT_DIR}/Int/SyscallHandler.brc" \
\
"${SCRIPT_DIR}/drivers/drv_serial.brc" \
"${SCRIPT_DIR}/processes/scheduler.brc" \
"${SCRIPT_DIR}/Storage/Storage.brc" \
"${SCRIPT_DIR}/Storage/StorageDevice/StorageDevice.brc" \
"${SCRIPT_DIR}/Storage/StorageDevice/BiosBootStorageDevice.brc" \
"${SCRIPT_DIR}/Storage/StorageArea/StorageArea.brc" \
"${SCRIPT_DIR}/Storage/StorageFs/StorageFs.brc" \
"${SCRIPT_DIR}/Storage/StorageFs/StorageFsFat.brc" \
\
"${SCRIPT_DIR}/Drivers/Cmos/DrvCmos.brc" \

check

nasm  -f elf32 -o int_raw.o "${SCRIPT_DIR}/Int/int_raw.asm"
check

ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin \
term.o \
main.o \
mem.o \
drv_keyboard.o \
BiosService.o \
int_raw.o \
Int.o \
drv_serial.o \
scheduler.o \
Storage.o \
DrvCmos.o \