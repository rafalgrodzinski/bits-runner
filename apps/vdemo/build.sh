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

IFS=$'\n'

SOURCES=()
for SOURCES_DIR in "${SCRIPT_DIR}/" "${BLIB}/" "${LIB}"; do
    FILES=`find "${SOURCES_DIR}" -name *.brc -print`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done

rm *.o 2> /dev/null

brb ${FLAGS[@]} ${SOURCES[@]}
check

ld.lld -T "${SCRIPT_DIR}/app.ld" -o vdemo.bin  *.o
check