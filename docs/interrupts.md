# Interrupts

## Interrupt Frame
```
- eip
- cs
- eflags
- user esp // Only if called from user mode
- user ss // Only if called from user mode
```