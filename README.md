<div align="center">
  <p>
    <h1>Bits Runner</h1>
  </p>
  <p>
    A from-scratch x86 OS written in BRC and assembly
  </p>
  <p>
    <a href="https://github.com/rafalgrodzinski/bits-runner-builder"><img src="https://img.shields.io/badge/;-f5b31e?label=BRC&labelColor=202020"/></a>
    &nbsp;
    <a href="https://flint.cs.yale.edu/cs422/doc/art-of-asm/pdf/"><img src="https://img.shields.io/badge/ASM-navy"/></a>
    &nbsp;
    <a href="https://github.com/rafalgrodzinski/bits-runner"><img src="https://img.shields.io/github/stars/rafalgrodzinski/bits-runner"/></a>
    &nbsp;
    <a href="https://github.com/rafalgrodzinski/bits-runner/releases"><img src="https://img.shields.io/github/v/tag/rafalgrodzinski/bits-runner?label=Version&color=white"/></a>
    &nbsp;
    <a href="#"><img src="https://img.shields.io/github/repo-size/rafalgrodzinski/bits-runner?label=Repo%20Size&color=white"></img></a>
    &nbsp;
    <a href="https://github.com/rafalgrodzinski/bits-runner-builder/issues"><img src="https://img.shields.io/github/issues/rafalgrodzinski/bits-runner?label=Issues&color=white"></img></a>
  </p>
</div>

#
Bits Runner is a from-scratch, fully custom x86 operating system, written in [Bits Runner Code](https://github.com/rafalgrodzinski/bits-runner-builder) language, which has been created specifically for this project.

It's preemptive, multi tasking, with user mode and high resolution graphics. It runs on real hardware and provides native drivers for numerous devices. It's primarily a fun challenge and a learning opportunity, but a lot of the implementation details are fully applicable to the mainstream operating systems.

<div align="center">
  <img width="600" src="https://github.com/user-attachments/assets/c1628637-8eb3-4634-8f87-cc761a273efe" />
</div>

## 🧵 In this readme
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
