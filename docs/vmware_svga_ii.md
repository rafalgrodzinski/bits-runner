# VMWare SVGA II
It is a virtual graphics card provided in VMWare emulators and possibly others. It supports high resolution, 32bit color, 2D & 3D acceleration runnion on top of the host's card. Has a linear frame buffer. It behaves as a PCI device.

## IDs, registers, etc
#### PCI
- Vendor ID: `0x15ad`
- Device ID: `0x0405`
- Class: `0x03`
- Sub Class: `0x00`
- BAR0: Base Port
- BAR1: Frame buffer address
- BAR2: Command FIFO

#### Ports
- Base Port: BAR0 - 1
- Index Port: Base Port + 0
- Value Port: Base Port + 1

Base port value in BAR0 is 16 bit. Reads and writes to index and value ports are 32bit. Write/read to/from the value port has to be preceeded with register id write to the index port.

#### Registers
- ID (specs version): `0x00`
- CAPS (Capabilities): `0x11`
- ENABLE: `0x01`
- WIDTH: `0x02`
- HEIGHT: `0x03`
- BPP (Bits Per Pixel): `0x07`
- FB_START (Frame buffer start): `0x0d`
- FB_OFFSET (Frame buffer padding): `0x0e`
- FB_SIZE (Frame buffer size): `0x10`
- FIFO_START (Commands FIFO start): `0x12`
- FIFO_SIZE (Commands FIFO size): `0x13`

## Initialization
- Write `0x9000_0002` to `ID`, which is the latest specification
- Read back from `ID` and check if the values match
- Set `WIDTH`, `HEIGHT`, `BPP` to the desired values
- Write `1` to `ENABLE`, this will switch to the selected mode
- Read `FB_SIZE` and `FB_OFFSET`
- Using the returned size, map virtual memory to an address starting at `FB_START` or `BAR1` + `FB_OFFSET` (can be a direct mapping)
- Writting values directly to frame buffer memory should be reflected on the screen

## Additional Resources
- "VMWare SVGA-II" Basic description of how to initialize and basic registers, but not too much besides:
[https://wiki.osdev.org/VMWare_SVGA-II](https://wiki.osdev.org/VMWare_SVGA-II)
- "vmware-svga" Clone of the developer kit, has more detailed desciprtion and example code: [https://github.com/prepare/vmware-svga](https://github.com/prepare/vmware-svga)