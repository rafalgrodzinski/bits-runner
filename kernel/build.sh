#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
BRB_DIR="$(dirname "$(which brb)")/.."

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
    DrvCmos.o
    DrvKeyboard.o
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
    "${BRB_DIR}/lib/B"
    "${SCRIPT_DIR}/../lib/B/"
)

for SOURCES_DIR in "${SOURCES_DIRS[@]}"; do
    # find .brc files (except for BSys.brc, cause it is specific per system)
    FILES=`find "${SOURCES_DIR}" -name *.brc ! -name "BSys.brc" -type f`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done
# and add the Bits Runner specific BSys.brc
SOURCES+=("${SCRIPT_DIR}/../lib/B/BSys.brc")

# build the source
brb ${FLAGS[@]} ${SOURCES[@]}
check

# and the assembly files
nasm -f elf32 -o int_raw.o "${SCRIPT_DIR}/Int/int_raw.asm"
check

# and finally link everything
ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin ${OBJS[@]}