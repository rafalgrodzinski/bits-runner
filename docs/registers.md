# Registers

## Flags
16 bit mode uses `flags` whereas 32 bit mode uses `eflags`.
```
 0 CF (Carry Flag)
 1
 2 PF (Parrity Flag)
 3
 4 AF
 5
 6 ZF (Zero Flag)
 7 SF (Sign Flag)
 8 TF
 9 IF (Interrupt Flag)
10 DF
11 OF (Overflow Flag)
12
⋮  IOPL
13
14 NT
15
```

Flags cannot be changed directly, only through certain commands:
- `cli`/`sti` Clear/Set interrupt flag (IF). If cleared, only NMI (Non Maskable Interrupts) will be delivered.
- `pushfd`/`popfd` Pushes/pops flags to/from the stack. This allows the values to be modified directly.