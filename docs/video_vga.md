## Ports
- `0x03c4` SC Index
- `0x03c5` SC Data

- `0x03ce` GC Index
- `0x03cf` GC Data

- `0x03d4` CRTC Index
- `0x03d5` CRTC Data

- `0x03c2` Misc Output

- `0x03da` Input Status 1

- `0x03c7 (u8)` Palette color index source select
- `0x03c8 (u8)` Palette color index target select
- `0x03c9 (u8)` Palette color red, green, and blue values (three reads/writes)

## Registers
- `0x00` Set/Reset Value
- `0x01` Enable Set/Reset
- `0x02` Map Mask
- `0x05` Mode

## Color palette
To update current color palette:
- Write target color index byte to port `0x03c8`
- For write red, green, and blue bytes to port `0x03c9`
- After three writes, the target index is automatically incemented

To read current color palette:
- Write source color index byt to port `0x03c7`
- Read a byte three times for red, green, and blue from port `0x03c9`
- After three read, the source index is automatically incremented

## Additional Resources
- Free VGA Project [http://www.osdever.net/FreeVGA/home.htm](http://www.osdever.net/FreeVGA/home.htm)
- Mode X: The VGA's Hiden Mode [https://trevorwoollacott.com/mode-x-the-vgas-hidden-mode-0a6efa45e7b4](https://trevorwoollacott.com/mode-x-the-vgas-hidden-mode-0a6efa45e7b4)
- Michael Abrash’s Graphics Programming Black Book [https://www.jagregory.com/abrash-black-book/](https://www.jagregory.com/abrash-black-book/)