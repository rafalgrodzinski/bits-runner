# VMWare SVGA II
It is a virtual graphics card that can be used in VMWare, Virtual Box, QEMU (and possibily other VMs). It supports high resolution, 32bit color, 2D & 3D acceleration running on top of the host's card. Has a linear frame buffer and behaves like a PCI device.

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

## Framebuffer

## Commands FIFO
There is a circular commands buffer that is used to update the screen, set cursors, draw primitives, etc. It's start address is in `SVGA_REG_FIFO_START` and the length is `SVGA_REG_FIFO_SIZE`. Each entry is 4 bytes. The first 4 entries are occupied by registers. You have to map the provided address to use it from virtual memory.
```sh
[0]: SVGA_FIFO_MIN # Lowest available commands offset in bytes, so it should be 16 in this case (skipping the 4 registers)
[1]: SVGA_FIFO_MAX # Maximum command offset in bytes, so this should be set to `SVGA_REG_FIFO_SIZE `
[2]: SVGA_FIFO_NEXT_CMD # Once set, the commands until this point will be executed
[3]: SVGA_FIFO_STOP
```

To execute commands:
- Keep track of the next command index
- Write command or attribute at the next command index
- Increse the slot value
- If we went over `SVGA_FIFO_MAX`, loop back to `SVGA_FIFO_MIN` (both are in bytes)
- Repeat for as many commands as necessary
- Update `SVGA_FIFO_NEXT_CMD` with the next command index that you've been keeping track of (multiply by 4 since it has to be in bytes) to commit the messages queue

## Initialization
- Write `0x9000_0002` to `ID`, which is the latest specification
- Read back from `ID` and check if the values match
- Set `WIDTH`, `HEIGHT`, `BPP` to the desired values
- Write `1` to `ENABLE`, this will switch to the selected mode
- Read `FB_SIZE` and `FB_OFFSET`
- Using the returned size, map virtual memory to an address starting at `FB_START` or `BAR1` + `FB_OFFSET` (can be a direct mapping)
- Writting values directly to frame buffer memory should be reflected on the screen

## Reference

### Registers
```sh
0x02 SVGA_REG_ID # Used to negotiate specification ID
0x01 SVGA_REG_ENABLE # Set to 1 once configuration is done to enter graphical mode

0x02 SVGA_REG_WIDTH # Read/write current screen width
0x03 SVGA_REG_WIDTH # Read/write current screen height
0x07 SVGA_REG_BPP # Read/write current bits per pixel
0x0c SVGA_REG_BYTES_PER_LINE # Pitch in bytes of each line (since there may be additional padding)

0x0d SVGA_REG_FB_START # Address of the framebuffer
0x0e SVGA_REG_FB_OFFSET # Offset from the frambuffer address to the start of the frambuffer
0x10 SVGA_REG_FB_SIZE # Size of the framebuffer

0x12 SVGA_REG_FIFO_START # Start address of the commands buffer
0x13 SVGA_REG_FIFO_SIZE # Size of the commands buffer

0x14 SVGA_REG_CONFIG_DONE # Set to 1 to once FIFO is configured
0x15 SVGA_REG_SYNC # Set to 1 to flush FIFO commands
0x16 SVGA_REG_BUSY # 1 Indicates that commands are being processed
```

### Commands
List of available commands with arguments
```sh
0x01 SVGA_CMD_UPDATE # Issue screen update
    x, y, width, height
```

## Additional Resources
- "VMWare SVGA-II" Basic description of how to initialize and basic registers, but not too much besides:
[https://wiki.osdev.org/VMWare_SVGA-II](https://wiki.osdev.org/VMWare_SVGA-II)
- "vmware-svga" Clone of the developer kit, has more detailed desciprtion and example code: [https://github.com/prepare/vmware-svga](https://github.com/prepare/vmware-svga)