# Bits Runner
Bits Runner is a 32bit operating system for x86 computers.

<img width="800" src="https://github.com/user-attachments/assets/7e593201-c37a-4a2d-8fcd-d435bf4734d3" />

## Quick Links
- [Extra Information](docs/Extra.md)

## Overview
Bits Runner is a simple, 32bit operating system for x86. It is built using assembly and [BRC (Bits Runner Code)](https://github.com/rafalgrodzinski/bits-runner-code) language.

## Main Features
It is under early development but the the desired design includes:
- Monolithic
- Support for user mode processes
- Paged virtual memory 
- Preemptive multitasking
- File system abstraction supporting multiple formats
- Graphics abstraction for both 2D and 3D (software mode)
- Sound abstraction (PC speakr, sound cards)
- Networing

## How to build & run
Building works on macOS. Support for Linux may be added at a later point.

Make sure you have [nasm](https://github.com/netwide-assembler/nasm) and [BRC](https://github.com/rafalgrodzinski/bits-runner-code) in your run path. Execute `/.make.sh`, which should produce a `floppy.img`, which is a FAT12 formatted floppy disk image. Run on your favourite virtual machine (tested on VM Ware and Bochs).

## Notes
The HDD image uses [MBiRa](https://github.com/alexfru/MBiRa) as the MBR boot manager.