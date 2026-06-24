# Bits Runner
Bits Runner is a 32 bit operating system for x86, written in [BRC (Bits Runner Code)](https://github.com/rafalgrodzinski/bits-runner-builder) language, which has been created specifically for this project.

It already boots from a floppy and a hard disk on a real hardware. It supports paged virual memory, preemptive multitasking, user mode processes, FAT 12/16, PS/2 keyboard and mouse, and VGA.

</video><img width="600" src="https://github.com/user-attachments/assets/c1628637-8eb3-4634-8f87-cc761a273efe" />

### In this readme
- [💾 How to run](README.md#-how-to-run)
- [🧩 Features](README.md#-features)
- [🛠️ How to build](README.md#-how-to-build)
- [🔗 Further resources](README.md#-further-resources)


## 🧩 Features
### Already working
- Boots on real hardware both from a floppy and a hard disk
- Paged virtual memory
- Preemptive multi-tasking
- User mode processes
- FAT 12/16
- PS/2 mouse & keyboard input
- VGA mode X

### Planned
- FAT 32
- Hardware abstraction layer
- Hardware acceleration for simple graphics cards (S3 Virge, Intel Extreme Graphics, etc)
- Sound (PC speaker, Sound Blaster)
- Networking
- USB
- CD support
- Maybe 64 bit CPU support?


## 💾 How to run
You can download an fdd or hdd image from the [releases](https://github.com/rafalgrodzinski/bits-runner/releases) page. On macOS or Linux use the `dd` command to prepare a disk. For example on macOS `sudo dd if=hdd.img of=/dev/disk<NUMBER> status=progress` will copy the image to a USB drive, which then can be used to boot the system in an hdd emulation mode.


## 🛠️ How to build
Building works on macOS. Support for Linux may be added at a later point.

Make sure you have [nasm](https://github.com/netwide-assembler/nasm) and [BRC](https://github.com/rafalgrodzinski/bits-runner-builder) installed and in your run path. Execute `./make.sh`, which will produce `fdd.img` and `hdd.img`, which are correspondigly FAT12 formatted floppy disk image and a hard drive image with two partitions, one FAT12 and one FAT16. `./create_images.sh` will in addition convert the `hdd.img` into formats that can be used by different virual machines.


## Further resources
- [Extra Information](docs/extra.md)
- [Paging](docs/paging.md)
- [PS/2 Input](docs/ps2_input.md)
- [VGA](docs/vga.md)
- [VMWare SVGA II](docs/vmware_svga_ii.md)
- [Timers](docs/timers.md)

### Notes
The HDD image uses [MBiRa](https://github.com/alexfru/MBiRa) as the MBR boot manager.
