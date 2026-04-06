#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
BRC_LIB="`brew --prefix`/lib/brc"

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
    Int.o
    int_raw.o
    Mem.o
    Sched.o
    Storage.o
    Term.o
)

# don't split on spaces, only on new lines
IFS=$'\n'

SOURCES=()

# For each of these directories
SOURCES_DIRS=(
    "${SCRIPT_DIR}/"
    "${BRC_LIB}/B"
    "${SCRIPT_DIR}/../lib/B/"
)

for SOURCES_DIR in "${SOURCES_DIRS[@]}"; do
    # find .brc files (except for BSys.brc, cause it is specific per system)
    FILES=`find "${SOURCES_DIR}" -name *.brc ! -name "BSys.brc" ! -name "*Storage*.brc" -type f | sort`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done
# and add the Bits Runner specific BSys.brc
SOURCES+=("${SCRIPT_DIR}/../lib/B/BSys.brc")

# Storage files need to be specifically ordered
SOURCES+=("${SCRIPT_DIR}/Storage/Storage.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageDevice/StorageDevice.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageDevice/BiosBootStorageDevice.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageArea/StorageArea.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageFs/StorageFs.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/StorageFs/StorageFsFat.brc")

# build the source
brb ${FLAGS[@]} ${SOURCES[@]}
check

# and the assembly files
nasm -f elf32 -o int_raw.o "${SCRIPT_DIR}/Int/int_raw.asm"
check

# and finally link everything
ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin ${OBJS[@]}