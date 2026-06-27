# Timers

## PIT (Programmable Interval Timer)
Runs at 1,193 182 MHz but has only a 16 divider, which give a teorethical limit at 18 Hz.

Channel 0 is connected to IRQ 0.
Channel 1 is unused (was used for refreshing DRAM)
Channel 2 is connected to PC speaker

Ports:
- `0x40` Channel 0 data
- `0x41` Channel 1 data
- `0x42` Channel 2 data
- `0x43` Mode/Command

Mode/Command:
```
0 Binary (0)/BCD (1) mode
---
1
⋮ Operating mode: 
3 000: Interrupt on terminal count
  001: Hardware re-triggerable one-shot
  010: Rate generator
  011: Square wave generator
  100: Software triggered strobe
  101: Hardware triggered strobe
  110: Also rate generator
  111: Also square wave generator
---
4
⋮ Access mode:
5 00: Latch count value command
  01: Low byte only
  10: Hight byte only
  11: Low & high byte
---
6
⋮ Channel:
7 00: Channel 0
  01: Channel 1
  10: Channel 2
```

### PC Speaker
Speaker is connected to Channel 2 of the PIT.

Port `0x61` is for keyboard controller, but is also used to enable the spaker:
```
0 Set to connect spaker to the PIT
---
1 Enable the speaker
```

In short, to use the speaker program the PIT and the set the two lowest bits in port `0x61`


## Additional Resources
- Programmable Interval Timer at OSDev Wiki:
[https://wiki.osdev.org/Programmable_Interval_Timer](https://wiki.osdev.org/Programmable_Interval_Timer)