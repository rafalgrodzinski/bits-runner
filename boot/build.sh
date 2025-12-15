#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

nasm -f bin -o boot_fat_12_16.bin "${SCRIPT_DIR}/boot_fat_12_16.asm"