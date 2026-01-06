#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
BRB_DIR="$(dirname "$(which brb)")/.."
SYS_DIR="${SCRIPT_DIR}/.."

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

brb --opt=o2 --gen=obj --verb=v2 --function-sections --triple=i686-unknown-linux-gnu --no-zero-initialized-in-bss --reloc=static \
"${SCRIPT_DIR}/main.brc" \
\
"${SCRIPT_DIR}/Mem/Mem.brc" \
\
"${SCRIPT_DIR}/Term/Term.brc" \
\
"${SCRIPT_DIR}/Drivers/Keyboard/DrvKeyboard.brc" \
"${SCRIPT_DIR}/BiosService.brc" \
\
"${SCRIPT_DIR}/Int/IntHandler.brc" \
"${SCRIPT_DIR}/Int/SyscallHandler.brc" \
\
"${SCRIPT_DIR}/Sched/Sched.brc" \
\
"${SCRIPT_DIR}/Storage/Storage.brc" \
"${SCRIPT_DIR}/Storage/StorageDevice/StorageDevice.brc" \
"${SCRIPT_DIR}/Storage/StorageDevice/BiosBootStorageDevice.brc" \
"${SCRIPT_DIR}/Storage/StorageArea/StorageArea.brc" \
"${SCRIPT_DIR}/Storage/StorageFs/StorageFs.brc" \
"${SCRIPT_DIR}/Storage/StorageFs/StorageFsFat.brc" \
\
"${SCRIPT_DIR}/Drivers/Cmos/DrvCmos.brc" \
\
"${BRB_DIR}/lib/B/String.brc" \
"${BRB_DIR}/lib/B/Date.brc" \
"${SYS_DIR}/lib/B/BSys.brc" \

check

nasm -f elf32 -o int_raw.o "${SCRIPT_DIR}/Int/int_raw.asm"
check

ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin \
Term.o \
main.o \
Mem.o \
DrvKeyboard.o \
BiosService.o \
int_raw.o \
Int.o \
Sched.o \
Storage.o \
DrvCmos.o \
B.o \
BSys.o \