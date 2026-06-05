; Page Directory entry:
; <31-12: table adr> <11-8: ?> <7: PS(0)> <6: ?> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; PS: page size, 0 for 4KiB, A: accessed, PCD: cache disabled, PWT: write through, US: users/supervisor, RW: read/write, P: present

; Page Table entry:
; <31-12: mem adr> <11-9: ?> <8: G> <7: PAT> <6: D> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; G: global (don't invalidate upon mov to cr3), PAT: caching type, D: dirty, A: accessed, PCD: cache disabled, PWT: write through, US: user/supervisor, RW: read/write, P: present

;
; Initialize memory manager
%define .args_count 2
%define .page_directory_adr [ebp + 8]
%define .kernel_pages_count [ebp + 12]
[bits 32]
memory_setup_paging_32:
    push ebp
    mov ebp, esp

    ; zero target memory (directory + 3 tables)
    mov ecx, 0x400 * 4
    mov eax, .page_directory_adr
.loop_zero_memory:
    mov dword [eax], 0
    add eax, 4
    loop .loop_zero_memory

    ; setup page directory
    mov eax, .page_directory_adr
    mov ebx, .page_directory_adr

    ; page_table_0
    ; 0x0000 0000 - 0x0040 0000 (0 - 4MiB)
    add eax, 0x1000 ; page_directory_adr + 4096 * 1
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 0 * 4], eax

    ; page_table_512
    ; 0x8000 0000 - 0x8040 0000 (2048 - 2052 MiB) kernel image
    add eax, 0x1000 ; page_directory_adr + 4096 * 2
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 512 * 4], eax

    ; page_table_1022
    ; 0xff80 0000 - 0xffc0 0000 (4088 - 4092 MiB) kernel stack
    add eax, 0x1000 ; page_directory_adr + 4096 * 3
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 1022 * 4], eax

    ; map tables
    mov ebx, .page_directory_adr

    ; Identity map the first MiB
    mov ecx, 0
    add ebx, 0x1000 ; page_directory_adr + 4096 * 1
.loop_0:
    mov eax, 0x1000
    mul ecx
    or eax, 0x03 ; RW & P
    mov [ebx + ecx * 4], eax

    inc ecx
    cmp ecx, 256
    jb .loop_0

    ; Map kernel image + heap
    mov ecx, 0
    add ebx, 0x1000 ; page_directory_adr + 4096 * 2
.loop_512:
    mov eax, 0x1000
    mul ecx
    add eax, KERNEL_PHY_ADR
    or eax, 0x03 ; RW & P
    mov [ebx + ecx * 4], eax

    inc ecx
    cmp ecx, .kernel_pages_count
    jb .loop_512

    ; Map kernel stack
    mov ecx, 0x40 ; 64 pages * 4096 = 256KiB
    add ebx, 0x1000 ; page_directory_adr + 4096 * 3
.loop_1022:
    mov eax, 0x1000
    mul ecx
    add eax, KERNEL_STACK_PHY_END_ADR - KERNEL_STACK_SIZE - 0x1000 ; map from the end
    or eax, 0x03 ; RW & P
    mov [ebx + (ecx + 1024 - 64 - 1)  * 4], eax ; map the last 256KiB
    loop .loop_1022

    ; Point last entry to page directory
    mov eax, .page_directory_adr
    mov ebx, .page_directory_adr
    and eax, 0xfffff000
    or eax, 0x13 ; PCD & RW & P
    mov [ebx + 1023 * 4], eax

    ; Enable paging
    mov eax, .page_directory_adr
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    mov esp, ebp
    pop ebp
    ret 4 * .args_count
%undef .kernel_pages_count
%undef .page_directory_adr
%undef .args_count