



<div align="center">
  <p>
    <img width=96 src="https://github.com/rafalgrodzinski/bits-runner/blob/main/img/Logo.png"/>
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
  <video width=500 src="https://github.com/user-attachments/assets/8cde1be2-c761-49a7-adcb-39e8607f2d13"/>
</div>

## 🧵 In this readme
- [🧩 Features](README.md#-features)
- [💾 How to run](README.md#-how-to-run)
- [🛠️ How to build](README.md#-how-to-build)
- [🔗 More info](README.md#-more-info)

## 🧩 Features
### Already working
- Boots on real hardware both from a floppy or a hard disk
- Paged, per process virtual memory
- Preemptive multi-tasking
- User mode processes and resources
- FAT 12/16
- PS/2 mouse & keyboard input
- VGA/VESA support
- Timer, PC speaker

### Planned
- FAT 32
- Hardware acceleration for simple graphics cards (S3 Virge, Intel Extreme Graphics, etc)
- Sound (AC97, Sound Blaster)
- Networking
- USB
- CD support
- Loadable drivers
- ELF
- Maybe 64 bit CPU support?

## 💾 How to run
Latest floppy and disk images are available from the [releases](https://github.com/rafalgrodzinski/bits-runner/releases) page.

### qemu
To run using qemu you can use the following commands:
- From floppy image: `qemu-system-i386 -drive file=fdd.img,if=floppy,format=raw`
- From hard disk image: `qemu-system-i386 -drive file=hdd.img,if=ide,format=raw`

To make the window stretchable, you can append `-display cocoa,zoom-to-fit=on` for macOS or `-display gtk,zoom-to-fit=on` for Linux.

### Real hardware
First you need to prepare a bootable medium. You can either put `fdd.img` on a floppy, `hdd.img` on a hard disk, or either one on a USB drive with appropriately set emulation mode in your computer's BIOS settings.

On macOS or Linux use the `dd` command to prepare a disk. For example on macOS `sudo dd if=fdd.img of=/dev/disk<NUMBER> status=progress` will copy the image to a specified floppy drive.

## 🛠️ How to build
Building works on macOS. Support for Linux may be added at a later point.

Make sure you have [nasm](https://github.com/netwide-assembler/nasm) and [BRC](https://github.com/rafalgrodzinski/bits-runner-builder) installed and in your run path. Execute `./make.sh`, which will produce `fdd.img` and `hdd.img`, which are correspondigly FAT12 formatted floppy disk image and a hard drive image with two partitions, one FAT12 and one FAT16. `./create_images.sh` will in addition convert the `hdd.img` into formats that can be used by different virual machines.

## 🔗 More info
Unique thing about OS development is that it touches almost every topic related to software (or even hardware) engineering. Every feature requires you to learn and understand many different topics such as how CPUs work (virtual memory, interrupts, registers, etc), protocols used by various devices (PS/2 mice, PCI devices, video buffers), algorithms (you need to implement everything, sorting, allocators, hash maps, etc), or even how data is stored (file systems, file formats). Basically, it's a never ending learning process. I'm trying to (a bit chaotically) record my findings, catalog information sources or just keep track of things for further use. Maybe you'll find it useful either for your own projects or just out of curiousity. All the various documents are under `docs/` folder.

- [BIOS calls](docs/bios.md)

- [Interrupts](docs/cpu_interrupts.md)
- [CPU registers](docs/cpu_registers.md)

- [Input PS/2](docs/input_ps2.md)

- [Virtual(Paged) memory](docs/memory_paging.md)
- [Heap management](docs/memory_alloc.md)

- [FAT 12/16](docs/storage_fat.md)

- [PCI](docs/pci.md)
- [Timers](docs/timers.md)

- [Video VGA](docs/video_vga.md)
- [Video VESA](docs/video_vesa.md)
- [Video VMWare SVGA II](docs/video_svga2.md)

- [Audio PC Speaker](docs/audio_pc_speaker.md)

- [Extra Information](docs/extra.md)

### Notes
The HDD image uses [MBiRa](https://github.com/alexfru/MBiRa) as the MBR boot manager.
