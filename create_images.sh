#!/bin/bash

PROJ_DIR="${HOME}/Workspace/Bits Runner"
OUT_DIR="${HOME}/Downloads"
export PREFIX="${PROJ_DIR}/bits-runner-builder"
./make.sh
if [ $? -ne 0 ]; then
    exit 1
fi

# FDD
cp fdd.img "${OUT_DIR}/bits_runner_fdd.img"

# VMWare
rm "${OUT_DIR}/bits_runner_hdd.vmdk" &> /dev/null
VBoxManage convertfromraw hdd.img "${OUT_DIR}/bits_runner_hdd.vmdk" --format VMDK --uuid=182b4980-6880-483c-a9d1-2c6c18e02645

# VirtualBox
rm "${OUT_DIR}/bits_runner_hdd.vdi" &> /dev/null
VBoxManage convertfromraw hdd.img "${OUT_DIR}/bits_runner_hdd.vdi" --format VDI --uuid=182b4980-6880-483c-a9d1-2c6c18e02645

# Bochs & Virtual PC
rm "${OUT_DIR}/bits_runner_hdd.vhd" &> /dev/null
VBoxManage convertfromraw hdd.img "${OUT_DIR}/bits_runner_hdd.vhd" --format VHD