#!/bin/sh

function check {
    if [ $? -ne 0 ]; then
        echo
        echo "⛔️ ${1}, aborting..."
        exit 1
    fi
}

VOLUME_NAME="DUMMY OS"

# Compile code
nasm -f bin -o boot.bin boot.asm
check "Failed to compile source"

nasm -f bin -o kernel.bin kernel.asm
check "Failed to compile source"

# Generate empty image file
dd if=/dev/zero bs=512 count=2880 of=floppy.img
# Attach and format the file
DISK=`hdiutil attach floppy.img -nomount`
newfs_msdos -F 12 -v "${VOLUME_NAME}" ${DISK}
# Overrite the boot sector
dd if=boot.bin of=${DISK}
diskutil eject ${DISK}
# Mount and copy a file into it
DISK=`hdiutil attach floppy.img`
cp kernel.bin /Volumes/"${VOLUME_NAME}"/
diskutil eject ${DISK}
