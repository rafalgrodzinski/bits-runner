#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

nasm -f bin -o bios_svc.bin "${SCRIPT_DIR}/main.asm"
