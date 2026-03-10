#!/bin/sh

function check {
    if [ $? -ne 0 ]; then
        echo
        echo "⛔️ ${1}, aborting..."
        exit 1
    fi
}

VOLUME_NAME="BITS RUNNER"
FAT_12_16_HEADER_SIZE=62
FAT_32_HEADER_SIZE=90

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

## Shell
echo "🛠️ Building shell..."
./apps/shell/build.sh
check "Failed to build shell"

echo

## VDemo
echo "🛠️ Building vdemo..."
./apps/vdemo/build.sh
check "Failed to build vdemo"

echo

## VDemo
echo "🛠️ Building count..."
./apps/count/build.sh
check "Failed to build count"

echo

# Create floppy image
echo "🛠️ Building FDD image..."
# Generate empty image file
rm fdd.img &> /dev/null
dd if=/dev/zero bs=512 count=2880 of=fdd.img &&

# Attach and format the file
DISK_FDD=`hdiutil attach fdd.img -nomount | xargs` &&
newfs_msdos -F 12 -v "${VOLUME_NAME}" "${DISK_FDD}" &&

# Overwrite the boot sector (but keep the FAT header intact)
dd if=boot_fat_12_16.bin of="${DISK_FDD}" bs=1 count=450 skip=${FAT_12_16_HEADER_SIZE} seek=${FAT_12_16_HEADER_SIZE} &&
diskutil eject "${DISK_FDD}" &&

# Mount and copy files
FDD_MOUNT_POINT=$(hdiutil attach fdd.img | grep -o '\/Volumes\/.*') &&
# copy system files
cp bios_svc.bin "${FDD_MOUNT_POINT}/" &&
cp kernel.bin "${FDD_MOUNT_POINT}/" &&
# copy apps
mkdir "${FDD_MOUNT_POINT}/apps" &&
cp shell.bin "${FDD_MOUNT_POINT}/apps/" &&
cp vdemo.bin "${FDD_MOUNT_POINT}/apps/" &&
cp count.bin "${FDD_MOUNT_POINT}/apps/" &&

hdiutil eject "${FDD_MOUNT_POINT}"
check "Failed to create FDD image"

echo

# Create 64 MiB hard disk image
echo "🛠️ Building HDD image..."

# Generate empty image file
rm hdd.img &> /dev/null
dd if=/dev/zero of=hdd.img bs=512 count=131072 &&

# Attach, partition, and format the image
DISK_HDD=`hdiutil attach hdd.img -nomount | xargs` &&
diskutil partitionDisk "${DISK_HDD}" 2 MBR "MS-DOS FAT12" "none1" 8M "MS-DOS FAT16" "none2" 80% &&
diskutil eject "${DISK_HDD}" &&

# Boot sectors
hdiutil attach hdd.img -nomount &&
# Overwrite drive boot sector
dd if=mbira.bin of="${DISK_HDD}" bs=446 count=1 &&
# Overwrite partition boot sector (but keep the FAT header intact)
dd if=boot_fat_12_16.bin of="${DISK_HDD}s1" bs=1 count=450 skip=${FAT_12_16_HEADER_SIZE} seek=${FAT_12_16_HEADER_SIZE} &&
dd if=boot_fat_12_16.bin of="${DISK_HDD}s2" bs=1 count=450 skip=${FAT_12_16_HEADER_SIZE} seek=${FAT_12_16_HEADER_SIZE} &&
diskutil eject "${DISK_HDD}" &&

# Mount and copy files to the first partition
HDD_MOUNT_POINT=$(hdiutil attach hdd.img | grep -o '\/Volumes\/.*' | head -1) &&
# copy system files
cp bios_svc.bin "${HDD_MOUNT_POINT}/" &&
cp kernel.bin "${HDD_MOUNT_POINT}/" &&
# copy apps
mkdir "${HDD_MOUNT_POINT}/apps" &&
cp shell.bin "${HDD_MOUNT_POINT}/apps/" &&
cp vdemo.bin "${HDD_MOUNT_POINT}/apps/" &&
cp count.bin "${HDD_MOUNT_POINT}/apps/" &&

hdiutil eject "${DISK_HDD}" &&
check "Failed to create HDD image"

# Mount and copy files to the second partition
HDD_MOUNT_POINT=$(hdiutil attach hdd.img | grep -o '\/Volumes\/.*' | tail -1) &&
# copy system files
cp bios_svc.bin "${HDD_MOUNT_POINT}/" &&
cp kernel.bin "${HDD_MOUNT_POINT}/" &&
# copy apps
mkdir "${HDD_MOUNT_POINT}/apps" &&
cp shell.bin "${HDD_MOUNT_POINT}/apps/" &&
cp vdemo.bin "${HDD_MOUNT_POINT}/apps/" &&
cp count.bin "${HDD_MOUNT_POINT}/apps/" &&

hdiutil eject "${DISK_HDD}" &&
check "Failed to create HDD image"

# Copy image files
cp fdd.img ~/Downloads/bits_runner_fdd.img
cp hdd.img ~/Downloads/bits_runner_hdd.img
rm ~/Downloads/bits_runner_hdd.vmdk &> /dev/null
VBoxManage convertfromraw hdd.img ~/Downloads/bits_runner_hdd.vmdk --format VMDK --uuid=182b4980-6880-483c-a9d1-2c6c18e02645
rm ~/Downloads/bits_runner_hdd.vdi &> /dev/null
VBoxManage convertfromraw hdd.img ~/Downloads/bits_runner_hdd.vdi --format VDI --uuid=182b4980-6880-483c-a9d1-2c6c18e02645
rm ~/Downloads/bits_runner_hdd.vhd &> /dev/null
VBoxManage convertfromraw hdd.img ~/Downloads/bits_runner_hdd.vhd --format VHD