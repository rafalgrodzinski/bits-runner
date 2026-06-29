# FAT 12/16

Directory entry (32 bytes):
```
0x00, 8: Name
0x08, 3: Extension
0x0b, 1: Attribute
2: Reserved
0x0e, 2: Creationg time
0x10, 2: Creation date
4: Reserved
0x16, 2: Modified time
0x18, 2: Modified date
0x1a, 2: First cluster
0x1c, 4: Size in bytes
```

Name byte 0:
```
0x00: Free entry (No more entries afterwards)
0xe5: Deleted entry (More entries afterwards)
0x05: First character of the name has value of 0xe5 (to avoid clash with deleted mark)
```

Attribue:
```
0 Read only
---
1 Hidden
---
2 System file
---
3 Volume name
---
4 Subdirectgory
---
5 Archive
---
6
⋮ Reserved
7
```

Free cluser:
FAT 12/16/32: `0x00`

Bad cluster:
FAT 12: `0xff7`
FAT 16: `0xfff7`
FAT 32: `0xffff_fff7`

End of chain:
FAT 12: `0xff8 - 0xffff`
FAT 16: `0xfff8 - 0xffff`
FAT 32: `0xffff_fff8 - 0xffff_ffff`