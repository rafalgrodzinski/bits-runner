# Paging
CR3 -> Page Tables Directory -> Pages Table -> Page

- cr3: Hold a physical address of page tables directory. Must be page aligned (multiples of 0x1000)
- Page Tables Directory: 1024 32-bit values (so an entire page). Each value is a physical address of a pages table. Also paged aligned. Covers 4GiB.
- Pages Table: 1024 32-bit values (so also an entire page). Each value is a physical address to which the corresponding linear (virtual) address will be matched. Covers 4MiB.
- Page: An entry in pages table. Covers 4KiB

Linear address = table_index * 0x40_0000 + page_index * 0x1000

## Enabling paging
Set bit 0 - PME (Protected mode enabled) in `cr0`.

Set `cr3` to 4096 bytes aligned (only bit 31-12 set) physical address of page directory entry.

Set bit 31 - PG (Paging) in `cr0`.

## Invalidate TLB
```
mov eax, cr3
mov cr3, eax
```

### Page Directory Entry (4KiB page)
```
0 P (Is present)
---
1 RW (Is read/write enabled)
---
2 US (Set for user acces, cleared for kernel only)
---
3 PWT (Set for write-through, cleared for write-back)
---
4 PCD (Set to disable caching)
---
5 A (Set by CPU if accessed, needs to be cleared manually)
---
6 D (Set by CPU if written (dirty))
---
7 PS (1) (If set, pages are 4MiB, cleared for 4KiB)
---
8
⋮ (Unused, can be set manually)
11
---
12
⋮ 4096 byte aligned page table entry address (physical address)
31
```
### Page Table Entry
```
0 P (Is present)
---
1 RW (Is read/write enabled)
---
2 US (Set for user acces, cleared for kernel only)
---
3 PWT (Set for write-through, cleared for write-back)
---
4 PCD (Set to disable caching)
---
5 A (Set by CPU if accessed, needs to be cleared manually)
---
6 D (Set by CPU if written (dirty))
---
7 PAT (Page Attribute Table, memory caching type)
---
8 G (Global, don't invalidate on cr3 update)
---
9
⋮ (Unused, can be set manually)
11
---
12
⋮ 4096 byte aligned page address (physical address)
31
```

## Resources
- "X86 Paging" - Thorough description of 32-bit and 64-bit paging:
[https://wiki.osdev.org/Paging](https://wiki.osdev.org/Paging)