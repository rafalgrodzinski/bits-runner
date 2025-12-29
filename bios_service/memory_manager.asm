org 0x2000
cpu 386
bits 32

heap_pointer: dd 0

align 4096
; <31-12: table adr> <11-8: ?> <7: PS(0)> <6: ?> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; PS: page size, 0 for 4KiB, A: accessed, PCD: cache disabled, PWT: write through, US: users/supervisor, RW: read/write, P: present
page_directory: times 1024 dd 0
; <31-12: mem adr> <11-9: ?> <8: G> <7: PAT> <6: D> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; G: global (don't invalidate upon mov to cr3), PAT: caching type, D: dirty, A: accessed, PCD: cache disabled, PWT: write through, US: user/supervisor, RW: read/write, P: present
page_table_0: times 1024 dd 0 ; 0x0000 0000 - 0x0040 0000 (0 - 4MiB)
page_table_512: times 1024 dd 0 ; 0x8000 0000 - 0x8040 0000 (2048 - 2052 MiB)
page_table_767: times 1024 dd 0 ; 0xbfc0 0000 - 0xc000 0000 (3068 - 3072 MiB)

;
; Initialize memory manager
memory_init:
    ; setup page directory
    mov eax, page_table_0
    and eax, 0xfffff000
    or eax, 3
    mov [page_directory], eax

    mov eax, page_table_512
    and eax, 0xfffff000
    or eax, 3
    mov [page_directory + 512 * 4], eax

    mov eax, page_table_767
    and eax, 0xfffff000
    or eax, 3
    mov [page_directory + 767 * 4], eax

    ; Identity map the first MiB
    mov ecx, 0
.loop_0:
    mov eax, 0x1000
    mul ecx
    or eax, 0x03 ; RW & P
    mov [page_table_0 + ecx * 4], eax

    inc ecx
    cmp ecx, 256
    jb .loop_0

    ; Map kernel memory
    mov ecx, 0
.loop_512:
    mov eax, 0x1000
    mul ecx
    add eax, 0x100000
    or eax, 0x03 ; RW & P
    mov [page_table_512 + ecx * 4], eax

    inc ecx
    cmp ecx, 1024
    jb .loop_512

    ; Map kernel stack
    mov ecx, 0x400
.loop_767:
    mov eax, 0x1000
    mul ecx
    add eax, 0x500000 - 0x1000
    or eax, 0x03 ; RW & P
    mov [page_table_767 + (ecx - 1)  * 4], eax
    loop .loop_767


    ; Point last entry to page directory
    mov eax, page_directory
    and eax, 0xfffff000
    or eax, 3
    mov [page_directory + 1023 * 4], eax

    ; Enable paging
    mov eax, page_directory
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ret
