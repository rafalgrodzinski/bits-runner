#!/bin/bash

VOLUME_NAME="DUMMY OS"

nasm -f bin -o boot.bin boot.asm

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
cp boot.asm /Volumes/"${VOLUME_NAME}"/
diskutil eject ${DISK}
