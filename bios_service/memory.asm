; Page Directory entry:
; <31-12: table adr> <11-8: ?> <7: PS(0)> <6: ?> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; PS: page size, 0 for 4KiB, A: accessed, PCD: cache disabled, PWT: write through, US: users/supervisor, RW: read/write, P: present

; Page Table entry:
; <31-12: mem adr> <11-9: ?> <8: G> <7: PAT> <6: D> <5: A> <4: PCD> <3: PWT> <2: US> <1: RW> <0: P>
; G: global (don't invalidate upon mov to cr3), PAT: caching type, D: dirty, A: accessed, PCD: cache disabled, PWT: write through, US: user/supervisor, RW: read/write, P: present

;
; Initialize memory maps, memory_size, and pages_count
[bits 16]
memory_scan_16:
    mov ebx, 0
    mov di, buffer

.loop:
    mov eax, 0xe820
    mov ecx, 24 ; 8 base + 8 size + 4 type
    mov edx, 0x534d4150 ; SMAP
    int 0x15
    
    ; process result
    inc byte [memory_map_entries_count] ; increase count of entries

    ; check if we found bigger memory limit
    cmp dword [di + 16], 2 ; check if marks unavailable regions
    je .size_not_updated
    mov eax, [di] ; region base address
    add eax, [di + 8] ; + region size
    cmp eax, [memory_size]
    jna .size_not_updated
    mov dword [memory_size], eax

.size_not_updated:
    add di, 24
    cmp ebx, 0 ; once ebx becomes 0, scanning has finished
    jne .loop

    ; calculate pages_count
    mov edx, 0
    mov ebx, PAGE_SIZE
    mov eax, [memory_size]
    div ebx ; eax <- memory_size / PAGE_SIZE
    mov [pages_count], eax

    ret

;
; Provide memory information to kernel
; in
;  layout_data_adr
;  pages_count
;  page_size
;  memory_map_entries_count
;  memory_map_entries_adr
;  kernel_image_size
%define .args_count 6
%define .layout_data_adr [ebp + 8]
%define .pages_count [ebp + 12]
%define .page_size [ebp + 16]
%define .memory_map_entries_count [ebp + 20]
%define .memory_map_entries_adr [ebp + 24]
%define .kernel_image_size [ebp + 28]
[bits 32]
memory_setup_kernel_memory_layout_info_32:
    push ebp
    mov ebp, esp

    sub sp, 4
    %define .current_map_entry [ebp - 0]

    ; setup layout info
    mov edi, .layout_data_adr

    mov ebx, .kernel_image_size
    mov [edi], ebx ; kernelImageSize

    mov ebx, .page_size
    mov dword [edi + 4], ebx ; pageSize

    mov ebx, .pages_count
    mov dword [edi + 8], ebx ; pagesCount

    mov ecx, 0 ; page currently being processed
.loop_page_entry:    
    ; calculate current address
    mov eax, ecx
    mul dword .page_size

    ; mark real mode memory
    cmp eax, 0x500 ; 1024 real mode IVT + 256 BDA
    jae .not_real_memory
    mov al, PAGE_UNAVAILABLE
    jmp .set_entry
.not_real_memory:

    ; mark kernel memory
    cmp eax, KERNEL_PHY_ADR
    jb .not_kernel_memory
    mov ebx, KERNEL_PHY_ADR
    add ebx, .kernel_image_size
    add ebx, PAGING_ENTRIES_SIZE + MEMORY_LAYOUT_INFO_SIZE
    add ebx, .pages_count ; + pages_count (1 byte per page)
    cmp eax, ebx
    jae .not_kernel_memory
    mov al, PAGE_KERNEL
    jmp .set_entry
.not_kernel_memory:

    ; mark kernel stack
    cmp eax, KERNEL_STACK_PHY_END_ADR - KERNEL_STACK_SIZE
    jb .not_kernel_stack_memory
    cmp eax, KERNEL_STACK_PHY_END_ADR
    jae .not_kernel_stack_memory
    mov al, PAGE_KERNEL_STACK
    jmp .set_entry
.not_kernel_stack_memory:

    ; mark bios service
    cmp eax, BIOS_SERVICE_ADR
    jb .not_bios_service_memory
    cmp eax, buffer + BUFFER_SIZE ; 512 bytes for read/write buffer
    jae .not_bios_service_memory
    mov al, PAGE_UNAVAILABLE
    jmp .set_entry
.not_bios_service_memory:

    ; search for memory map entry
    ; start search from the first entry
    mov dword .current_map_entry, 0
    mov esi, .memory_map_entries_adr
.loop_find_entry:
    ; Past last entry?
    mov ebx, .current_map_entry
    cmp ebx, .memory_map_entries_count
    jb .not_past_last_entry
    mov al, PAGE_UNAVAILABLE
    jmp .set_entry
.not_past_last_entry:

    ; within current entry?
    ; is below entry?
    cmp eax, [esi] ; < base?
    jb .try_next_entry

    ; is above entry?
    cmp eax, [esi + 8] ; >= base + length
    jae .try_next_entry

    ; is usable RAM?
    mov al, [esi + 16]
    cmp al, 1 ; 1: usable ram
    jne .not_usuable_ram
    mov al, PAGE_FREE
    jmp .set_entry
.not_usuable_ram:

    mov al, PAGE_UNAVAILABLE ; mark as unavailable
    jmp .set_entry

.try_next_entry:
    add esi, 24 ; go to the next entry
    inc dword .current_map_entry
    jmp .loop_find_entry

.set_entry:
    mov [edi + 12 + ecx], al
    inc ecx
    cmp ecx, .pages_count
    jb .loop_page_entry

    mov esp, ebp
    pop ebp
    ret 4 * .args_count
%undef .current_map_entry
%undef .kernel_image_size
%undef .memory_map_entries_adr
%undef .memory_map_entries_count
%undef .page_size
%undef .pages_count
%undef .layout_data_adr
%undef .args_count

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
    add eax, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 1
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 0 * 4], eax

    ; page_table_512
    ; 0x8000 0000 - 0x8040 0000 (2048 - 2052 MiB) kernel image
    add eax, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 2
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 512 * 4], eax

    ; page_table_1022
    ; 0xff80 0000 - 0xffc0 0000 (4088 - 4092 MiB) kernel stack
    add eax, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 3
    and eax, 0xfffff000
    or eax, 3
    mov [ebx + 1022 * 4], eax

    ; map tables
    mov ebx, .page_directory_adr

    ; Identity map the first MiB
    mov ecx, 0
    add ebx, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 1
.loop_0:
    mov eax, PAGE_SIZE
    mul ecx
    or eax, 0x03 ; RW & P
    mov [ebx + ecx * 4], eax

    inc ecx
    cmp ecx, 256
    jb .loop_0

    ; Map kernel image + heap
    mov ecx, 0
    add ebx, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 2
.loop_512:
    mov eax, PAGE_SIZE
    mul ecx
    add eax, KERNEL_PHY_ADR
    or eax, 0x03 ; RW & P
    mov [ebx + ecx * 4], eax

    inc ecx
    cmp ecx, .kernel_pages_count
    jb .loop_512

    ; Map kernel stack
    mov ecx, 0x40 ; 64 pages * 4096 = 256KiB
    add ebx, PAGING_ENTRY_SIZE ; page_directory_adr + 4096 * 3
.loop_1022:
    mov eax, PAGE_SIZE
    mul ecx
    add eax, KERNEL_STACK_PHY_END_ADR - KERNEL_STACK_SIZE - PAGE_SIZE ; map from the end
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