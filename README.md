# Bits Runner
Bits Runner is a 32bit operating system for x86 computers written in BRC language.

https://github.com/user-attachments/assets/e14b9e52-6a4e-43ad-8768-2606df7f3601

## Quick Links
- [Extra Information](docs/extra.md)
- [Paging](docs/paging.md)
- [PS/2 Input](docs/ps2_input.md)
- [VGA](docs/vga.md)
- [VMWare SVGA II](docs/vmware_svga_ii.md)

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

## How to run
You download an fdd or hdd image from the [releases](https://github.com/rafalgrodzinski/bits-runner/releases) page. You can then use `dd` to prepare a disk. For example on macOS `sudo dd if=hdd.img of=/dev/disk7 status=progress` could copy the image to a USB drive, which could then be used to boot the system in an hdd emultation (don't just copy this command, make sure that disk7 is your intended target disk).

## How to build
Building works on macOS. Support for Linux may be added at a later point.

Make sure you have [nasm](https://github.com/netwide-assembler/nasm) and [BRC](https://github.com/rafalgrodzinski/bits-runner-code) in your run path. Execute `/.make.sh`, which should produce a `fdd.img`, which is a FAT12 formatted floppy disk image. It will also produce `hdd.img` which contains a hard drive image with two partitions, one FAT12  and one FAT16. Run on your favourite virtual machine or real hardware (tested on VM Ware and Bochs).

## Notes
The HDD image uses [MBiRa](https://github.com/alexfru/MBiRa) as the MBR boot manager.
