#!/bin/sh

function check {
    if [ $? -ne 0 ]; then
        echo
        echo "⛔️ ${1}, aborting..."
        exit 1
    fi
}

VOLUME_NAME="BITS RUNNER"

# Boot
echo "🛠️ Building bootloader..."
nasm -f bin -o boot.bin boot/boot.asm
check "Failed to build bootloader"

echo

# BIOS Service
echo "🛠️ Building BIOS service..."
nasm -f bin -o bios_svc.bin boot/bios_service.asm
check "Failed to build BIOS service"

echo

# Kernel
echo "🛠️ Building kernel..."
nasm -f bin -o kernel.bin kernel/kernel.asm
check "Failed to build kernel"

echo

# Shell
echo "🛠️ Building shell..."
./shell/build.sh
check "Failed to build shell"

#echo

# Disk Image
echo "🛠️ Building disk image..."
# Generate empty image file
dd if=/dev/zero bs=512 count=2880 of=floppy.img
# Attach and format the file
DISK=`hdiutil attach floppy.img -nomount`
newfs_msdos -F 12 -v "${VOLUME_NAME}" ${DISK}
# Overrite the boot sector
dd if=boot.bin of=${DISK}
diskutil eject ${DISK}
# Mount and copy a file into it
MOUNT_POINT=$(hdiutil attach floppy.img | grep -o '\/Volumes\/.*')
cp bios_svc.bin "${MOUNT_POINT}/"
cp kernel.bin "${MOUNT_POINT}/"
cp shell.bin "${MOUNT_POINT}/"
hdiutil eject "${MOUNT_POINT}"
