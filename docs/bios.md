# BIOS

## Storage (int 0x13)
Storage read/write can be performed in CHS (Cylinder Head Sector) or LBA (Logical Block Addressing). Except for flopy disks (which can only be accessed using the CHS calls) the cylinder, head, and sector values don't have any physical correspondence to the actual drive.

With CHS addressing cylinder can be 0 to 1023 (BIOS limit), head 0 to 15 (ATA limit), sector 1 to 63 (BIOS limit). Sector 0 is invalid. That gives maximum supported size of 1024 * 16 * 63 = 1,032,192 sectors or 504MiB for the standard 512B sector. 1.44MB floppy has 80 cylinders, 2 heads, and 18 sectors.

There are two versions of LBA, 28bit (ATA-1) with 128GiB limit and 48bit (ATA-6) with 128 PiB limit. Both should be handled by BIOS seamlessly.

### Using CHS
- `ah`: `0x02` for reading or `0x03` for writting.
- `es:bx`: The source/destination buffer address
- `dl`: Drive number
- cylinder: `cl 7-6, ch 7-0`
- head: `dh`
- sector: `cl 5-0`
- `int 0x13`

Carry flag is clear for success, set for failure.

### Using LBA
Disk Address Packet (DAP) is required to setup the desired command
```
 Δ | # |
---+---+---
 0 | 2 | DAP size (0x10)
 2 | 2 | Sectors count
 4 | 2 | Transfer buffer segment
 6 | 2 | Transfer buffer offset
 8 | 8 | LBA address
```

- `ah`: `0x42` for reading or `0x43` for writing
- `dl`: Drive number
- `ds:si`: Address of DAP
- `int 0x13`

## Additional Resources
- "Disk access using the BIOS (INT 13h)" - Detailed desciription of using both the CHS and LBA BIOS calls: [https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)](https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h))
- "Int13h AH=42h Boot From Hard Drive just fails [Solved]" - Discussion about the usage of LBA [https://forum.osdev.org/viewtopic.php?t=20257](https://forum.osdev.org/viewtopic.php?t=20257)
- "CHS conversion": [http://www.fact-index.com/c/ch/chs_conversion.html](http://www.fact-index.com/c/ch/chs_conversion.html)