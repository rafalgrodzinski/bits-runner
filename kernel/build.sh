#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
PREFIX="${PREFIX:-`brew --prefix`}"
PATH="${PREFIX}/bin:${PREFIX}/build:${PATH}"
BLIB="${PREFIX}/lib/brc/B"

function check {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

# gather all the required build flags
FLAGS=(
    --opt=o2
    --gen=obj
    --verb=v2
    --function-sections
    --triple=i686-unknown-linux-gnu
    --no-zero-initialized-in-bss
    --reloc=static
)

# and resulting object files
OBJS=(
    main.o
    B.o
    BSys.o
    BiosService.o
    Bus.o
    DeviceKeyboard.o
    DeviceMouse.o
    DeviceVideo.o
    DrvCmos.o
    Devices.o
    Interrupt.o
    interrupt_handler.o
    Memory.o
    Dispatch.o
    Storage.o
    Term.o
)

# don't split on spaces, only on new lines
IFS=$'\n'

SOURCES=()

# For each of these directories
SOURCES_DIRS=(
    "${SCRIPT_DIR}/"
    "${BLIB}/"
)

for SOURCES_DIR in "${SOURCES_DIRS[@]}"; do
    # find .brc files (except for BSys.brc, cause it is specific per system)
    FILES=`find "${SOURCES_DIR}" -name *.brc ! -name "*Storage*.brc" ! -name Speaker.brc ! -name Pit.brc -type f | sort`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done

# Storage files need to be specifically ordered
SOURCES+=("${SCRIPT_DIR}/Storage/Storage.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageDevice/StorageDevice.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageDevice/BiosBootStorageDevice.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageArea/StorageArea.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageFs/StorageFs.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageFs/StorageFsFat.brc")
SOURCES+=("${SCRIPT_DIR}/Devices/Timer/Pit.brc")
SOURCES+=("${SCRIPT_DIR}/Devices/Audio/Speaker.brc")

# build the source
brb ${FLAGS[@]} ${SOURCES[@]}
check

# and the assembly files
nasm -f elf32 -o interrupt_handler.o "${SCRIPT_DIR}/Interrupt/interrupt_handler.asm"
check

# and finally link everything
ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin ${OBJS[@]}