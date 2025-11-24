#!/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

nasm -f bin -o boot.bin "${SCRIPT_DIR}/boot.asm"