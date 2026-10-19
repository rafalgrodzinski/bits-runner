# VESA

## Structs

VESA Info Block
```
 Δ  | #       |
---+---------+---
 0  | u8[4]   | VbeSignature: 'VESA' signature
 4  | u16     | VbeVersion: Version
 6  | u16[2]  | OemStringPtr: Pointer to OEM string (`[0]`: offset, `[1]`: segment)
 10 | u8[4]   | Capabilities
 14 | u16[2]  | VideoModePtr: Pointer to list of video modes, terminated by `0xffff` (`[0]`: offset, `[1]`: segment)
 18 | u16     | TotalMemory: Number of 64KiB blocks
 20 | u8[492] | Unused
 ```

 Mode Info
 ```
 Δ  | #       |
---+---------+---
 0 | u16 | ModeAttributes: `<7>`: Set if linear framebuffer is supported
 | u16 | XResolution
 | u16 | YResolution
 | u8 | BitsPerPixel
 ```


## Functions

### Get VESA Info Block `0x4f00`
- `ax`: `0x4f00`
- `es:di`: 512 bytes buffer for the output info block
- Output `ax`:

### Get Mode Info `0x4f01`
- `ax`: `0x4f01`
- `es:di`: 256 bytes buffer for the output info block
- `cx`: Mode
- Output `ax`:

### Set Mode `0x4f02`
- `ax`: `0x4f02`
- `bx`: `<13-0>`: Mode Numer, `<14>`: Set for linear framebuffer, clear for bank switching, `<15>`: If clear, BIOS clears the screen

### Get/set display start `0x4f07`
- `ax`: `0x0407`
- `bx`: `0x0000`: Set display start, `0x0001`: Get display start, `0x0080`: Set display start during VSync
- `cx`: Start x pixel
- `dx`: Start y pixel

## Additional Resources
- "VBE Core Funcions": [https://www.phatcode.net/res/221/files/vbe20.pdf](https://www.phatcode.net/res/221/files/vbe20.pdf)
- "VESA Tutorial": [https://wiki.osdev.org/User:Omarrx024/VESA_Tutorial](https://wiki.osdev.org/User:Omarrx024/VESA_Tutorial)
- "VBE Core Functions": [https://web.archive.org/web/20081211174813/http://docs.ruudkoot.nl/vbe20.txt](https://web.archive.org/web/20081211174813/http://docs.ruudkoot.nl/vbe20.txt)