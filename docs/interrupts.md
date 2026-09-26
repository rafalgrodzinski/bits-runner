# Interrupts

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