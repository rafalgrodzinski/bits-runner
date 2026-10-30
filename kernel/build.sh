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
    --triple=i386-unknown-none
    --arch=i386
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
    DrvCmos.o
    Devices.o
    Interrupt.o
    interrupt_handler.o
    Memory.o
    Dispatch.o
    Storage.o
    Term.o
    Video.o
    Input.o
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
    FILES=`find "${SOURCES_DIR}" \
    -type d -name Storage -prune -o \
    -type d -name Video -prune -o \
    -type d -name Input -prune -o \
    -type d -name Memory -prune -o \
    -name *.brc ! -name Speaker.brc ! -name Pit.brc -print | sort`
    for FILE in ${FILES}; do
        # and add them to the list
        SOURCES+=("${FILE}")
    done
done

# Files need to be specifically ordered

# Memory
SOURCES+=("${SCRIPT_DIR}/Memory/PagingManager.brc")
SOURCES+=("${SCRIPT_DIR}/Memory/HeapManager.brc")
SOURCES+=("${SCRIPT_DIR}/Memory/AllocatorFirstFit.brc")

# Storage 
SOURCES+=("${SCRIPT_DIR}/Storage/Storage.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Device/Device.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Device/DeviceBios.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Area/Area.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Entry/Entry.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Entry/MetadataFat.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Filesystem/Filesystem.brc")
SOURCES+=("${SCRIPT_DIR}/Storage/Filesystem/FilesystemFat.brc")
SOURCES+=("${SCRIPT_DIR}/Devices/Timer/Pit.brc")
SOURCES+=("${SCRIPT_DIR}/Devices/Audio/Speaker.brc")

# Input
SOURCES+=("${SCRIPT_DIR}/Input/Drivers/DriverPs2.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Keyboard/Keyboard.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Keyboard/KeyboardNone.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Keyboard/KeyboardBios.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Keyboard/KeyboardPs2.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Mouse/Mouse.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Mouse/MouseNone.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Mouse/MouseBios.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Mouse/MousePs2.brc")
SOURCES+=("${SCRIPT_DIR}/Input/Input.brc")

# Video
SOURCES+=("${SCRIPT_DIR}/Video/Video.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Surface/Surface.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Mode/ModeMetadataVesa.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Mode/ModeMetadataSvga2.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Mode/Mode.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Adapter/Adapter.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Adapter/AdapterNone.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Adapter/AdapterSvga2.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Adapter/AdapterVesa.brc")
SOURCES+=("${SCRIPT_DIR}/Video/Adapter/AdapterVga.brc")

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

# build the source
brb ${FLAGS[@]} ${SOURCES[@]}
check

# and the assembly files
nasm -f elf32 -o interrupt_handler.o "${SCRIPT_DIR}/Interrupt/interrupt_handler.asm"
check

# and finally link everything
ld.lld -T "${SCRIPT_DIR}/kernel.ld" -o kernel.bin ${OBJS[@]}