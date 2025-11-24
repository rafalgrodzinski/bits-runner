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
./boot/build.sh
check "Failed to build bootloader"

echo

# BIOS Service
echo "🛠️ Building BIOS service..."
./bios_service/build.sh
check "Failed to build BIOS service"

echo

# Kernel
echo "🛠️ Building kernel..."
./kernel/build.sh
check "Failed to build kernel"

echo

# Shell
echo "🛠️ Building shell..."
./shell/build.sh
check "Failed to build shell"

echo

## Create floppy image
#echo "🛠️ Building disk image..."
## Generate empty image file
#dd if=/dev/zero bs=512 count=2880 of=floppy.img
## Attach and format the file
#DISK=`hdiutil attach floppy.img -nomount`
#newfs_msdos -F 12 -v "${VOLUME_NAME}" ${DISK}
## Overrite the boot sector
#dd if=boot.bin of=${DISK}
#diskutil eject ${DISK}
## Mount and copy a file into it
#MOUNT_POINT=$(hdiutil attach floppy.img | grep -o '\/Volumes\/.*')
#cp bios_svc.bin "${MOUNT_POINT}/"
#cp kernel.bin "${MOUNT_POINT}/"
#cp shell.bin "${MOUNT_POINT}/"
#hdiutil eject "${MOUNT_POINT}"

# Create 64 MiB hard disk image
echo "🛠️ Building HDD image..."

# Generate empty image file
rm hdd.img &> /dev/null
dd if=/dev/zero of=hdd.img bs=512 count=131072

# Attach, partition, and format the image
DISK_HDD=`hdiutil attach hdd.img -nomount | xargs`
diskutil partitionDisk "${DISK_HDD}" 2 MBR "MS-DOS FAT12" "none1" 20% "MS-DOS FAT16" "none2" 80%
diskutil eject "${DISK_HDD}"

# Boot sectors
hdiutil attach hdd.img -nomount
# Overwrite drive boot sector
dd if=mbr.bin of="${DISK_HDD}" bs=446 count=1
# Overwrite partition boot sector
dd if=boot.bin of="${DISK_HDD}s1"

diskutil eject "${DISK_HDD}"

## Mount and copy files
HDD_MOUNT_POINT=$(hdiutil attach hdd.img | grep -o '\/Volumes\/.*' | head -1)
cp bios_svc.bin "${HDD_MOUNT_POINT}/"
cp kernel.bin "${HDD_MOUNT_POINT}/"
cp shell.bin "${HDD_MOUNT_POINT}/"
hdiutil eject "${DISK_HDD}"

# tmp
#cp floppy.img ~/Downloads/bits_runner_fdd.img
#rm ~/Downloads/bits_runner.vmdk
#VBoxManage convertfromraw ~/Downloads/bits_runner.img ~/Downloads/bits_runner.vmdk --format VMDK