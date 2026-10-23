# VESA

## Structs

VESA Info Block
```
 Δ  | #       |
---+----------+---
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
 Δ  | #  |
---+-----+---
0  | u16 | ModeAttributes: `<7>`: Set if linear framebuffer is supported
16 | u16 | XResolution
32 | u16 | YResolution
48 | u8  | BitsPerPixel
 ```


## BIOS Functions
```
Get VESA info block
in:
    ax: 0x4f00
    es:di: 512 bytes buffer for the output info block
out:
    ax: status
```

```
Get mode info
in:
    ax: 0x4f01
    cx: mode
    es:di: 256 bytes buffer for the output info block
out:
    ax: status
```

```
Set mode
in:
    ax: 0x4f02
    bx: <15> screen cleared if 0; <14> 1 for linear framebuffer, 0 for bank switching; <13-0> mode Numer
```

```
Get/set display start
in:
    ax: 0x4f07
    bx: 0x00 set display start; 0x80 set during VSync, 0x01 get display start
    cx: start column
    dx: start line
```

```
Get protected mode interface
in:
    ax: 0x4f0a
    bl: 0x00
out:
    es:di: address of functions table
    ax: 0x004f for success
```
The returned value is the address with a list of functions that can be called directly from protected mode:
```
[es:di + 0x00] Set window call

[es:di + 0x02] Set display start
in:
    ax: 0x4f07
    bx: 0x00 set display start; 0x80 set during VSync, 0x01 get display start
    cx: high 16 bits of the address divided by 4
    dx: low 16 bits of the address

[es:di + 0x04] Set palette data
```

```
Get/Set colors palette
in:
    ax: 0x4f09
    bl: 0x00 set, 0x01 get
    cx: number of colors to set (max 256)
    dx: starting at index
    es:di: source/target palette data
out:
    ax: status
```
Palette data is a list of 4-byte entries: `blue`, `green`, `red`, `padding`. Like for VGA, each can take a 6 bit value (the top 2 bits are ignored) so the values can be in range 0..63.

## Additional Resources
- "VBE Core Funcions": [https://www.phatcode.net/res/221/files/vbe20.pdf](https://www.phatcode.net/res/221/files/vbe20.pdf)
- "VESA Tutorial": [https://wiki.osdev.org/User:Omarrx024/VESA_Tutorial](https://wiki.osdev.org/User:Omarrx024/VESA_Tutorial)
- "VBE Core Functions": [https://web.archive.org/web/20081211174813/http://docs.ruudkoot.nl/vbe20.txt](https://web.archive.org/web/20081211174813/http://docs.ruudkoot.nl/vbe20.txt)