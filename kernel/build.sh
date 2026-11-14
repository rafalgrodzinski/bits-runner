#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
[ -d "${PREFIX}"] || PREFIX="$(brew --prefix)"
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
    --triple=i386-unknown-none
    --arch=i386
    --no-zero-initialized-in-bss
    --reloc=static
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
    FILES=`find "${SOURCES_DIR}" -name *.brc -print`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done

#echo -n "\"args\": ["
#for FLAG in "${FLAGS[@]}"; do
#    echo -n "\"${FLAG}\", "
#done
#
#for SOURCE in "${SOURCES[@]}"; do
#    echo -n "\"${SOURCE}\", "
#done
#echo -e "\b\b],"
#
#exit 1

# Get rid of previously generated object files
rm *.o 2> /dev/null

# build the source
brb ${FLAGS[@]} ${SOURCES[@]}
check

# and the assembly files
nasm -f elf32 -o interrupt_handler.o "${SCRIPT_DIR}/Interrupt/interrupt_handler.asm"
check

# and finally link everything
ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin *.o
check