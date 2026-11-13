# Registers

## Flags
16 bit mode uses `flags` whereas 32 bit mode uses `eflags`.
```
 0 CF (Carry Flag)
 1
 2 PF (Parrity Flag)
 3
 4 AF (Auxuiliary Carry Flag)
 5
 6 ZF (Zero Flag)
 7 SF (Sign Flag)
 8 TF (Trap Flag)
 9 IF (Interrupt Enable Flag)
10 DF (Direction Flag)
11 OF (Overflow Flag)
12
⋮  IOPL (Input/Output priviledge flag)
13
14 NT (Nested task flag)
15
16 RF (Resume flag)
17 VM (Virtual 8086 mode flag)
```

Flags cannot be changed directly, only through certain commands:
- `cli`/`sti` Clear/Set interrupt flag (IF). If cleared, only NMI (Non Maskable Interrupts) will be delivered.
- `pushfd`/`popfd` Pushes/pops flags to/from the stack. This allows the values to be modified directly.

## Additional Resources
- "EFLAGS Individual Bit Flags": [https://www.c-jump.com/CIS77/ASM/Instructions/I77_0070_eflags_bits.htm](https://www.c-jump.com/CIS77/ASM/Instructions/I77_0070_eflags_bits.htm)