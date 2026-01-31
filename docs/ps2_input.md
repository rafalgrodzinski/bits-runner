# PS/2 Input

Controller tatus register:
```
0 Output buffer status (1: full)
---
1 Input buffer status (1: full)
---
2 System flag
---
3 Command/Data (0: data to PS/2 device, 1: data to PS/2 controller)
---
4 ?
---
5 ?
---
6 Time-out error (0: no error)
---
7 Parity error (0: no error)
```

Controller configuration register
```
0 Enable first port ints (1: enabled)
---
1 Enable second port ints (1: enabled)
---
2 System flag (1: POST passed)
---
3 (0)
---
4 Disable first port clock (1: disabled, 0: enabled)
---
5 Disable second port clock (1: disabled, 0: enabled)
---
6 First port translation
---
7 (0)
```

## Mouse ports and commands
Ports:
- `0x64` Command port
- `0x60` Data port

Commands:
- `0xa8` Enable second PS/2 port
- `0xf3` Set sample rate
- `0xd4` Send data to second PS/2 port
- `0x20` Get status
- `0x60` Set status
- `0xf4` Enable data reporting
- `0xff` Reset
- `0xf6` Set defaults

## Mouse interrupt received data
Standard 3 buttons mode
```
0  Button Left
---
1  Button Middle
---
2  Button Right
---
3  (1)
---
4  X axis sign
---
5  Y axis sign
---
6  X axis overflow
---
7  Y axis overflow
---
8
⋮  X axis delta (2 complements)
15
---
16
⋮  Y axis delta (2 complement)
23
```

Scroll wheel mode
```
24
⋮  Scroll wheel delta (2 complements)
31
```

5-button + scroll wheel mode
```
24
⋮  Scroll wheel delta (2 complements)
27
---
28 Button 4
---
29 Button 5
---
30
⋮  (0)
31
```

## Additional Resources
- Mouse Input
(https://wiki.osdev.org/Mouse_Input)[https://wiki.osdev.org/Mouse_Input]

- PS/2 Mouse
(https://wiki.osdev.org/PS/2_Mouse)[https://wiki.osdev.org/PS/2_Mouse]

- The PS/2 Mouse Interface
(https://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/datasheets/PS2%20Mouse%20Protocol.htm)[https://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/datasheets/PS2%20Mouse%20Protocol.htm]

- I8042 PS/2 Controller
(https://wiki.osdev.org/I8042_PS/2_Controller#Detecting_PS/2_Device_Types)[https://wiki.osdev.org/I8042_PS/2_Controller#Detecting_PS/2_Device_Types]