# Interrupts

## PIC (Programmable Interrupt Controller)
IRQs (Interrupt Requests) are handled by two 8259A PIC controllers. Slave PIC is connected to the master on IRQ 2.

```
IRQ | Device
----+----
 0  | PIT Timer
 1  | PS/2 Keyboard
 2  | Cascade to slave PIC
 3  | COM1
 4  | COM2
 5  |
 6  | Floppy
 7  | LPT1
 8  | RTC
 9  |
10  |
11  |
12  | PS/2 Mouse
13  | FPU
14  |
15  |
```

Ports:
- `0x20` Master Command
- `0x21` Master Data
- `0xa0` Slave Command
- `0xa1` Slave Date

It's best to disable all IRQs by masking them (except for cascade IRQ 2) and then only enable the ones that we are actually using. IRQs can be masked by writting to the corresponding data port. `0x00` unmasks, `0xff` masks every interrupt.


## Interrupt Frame
```
- eip
- cs
- eflags
- user esp // Only if called from user mode
- user ss // Only if called from user mode
```

## Additional Resources
- "Interrupt Descriptor Table": [https://wiki.osdev.org/Interrupt_Descriptor_Table](https://wiki.osdev.org/Interrupt_Descriptor_Table)
- "8259 PIC": [https://wiki.osdev.org/8259_PIC](https://wiki.osdev.org/8259_PIC)