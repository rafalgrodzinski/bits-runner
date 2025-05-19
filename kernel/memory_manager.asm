cpu 386
bits 32

heap_pointer: dd 0

align 4096
page_directory: times 1024 dd 0
page_table: times 1024 dd 0

;
; Initialize memory manager
memory_init:

    mov dword [heap_pointer], heap + ADDRESS_KERNEL

    ; Setup first page table
    mov ecx, 0
    mov edi, page_table + ADDRESS_KERNEL
    mov eax, 0
.loop:
    mov ebx, eax
    and ebx, 0xfffff000
    or ebx, 3

    mov [edi], ebx

    add eax, 4096
    add edi, 4
    inc ecx
    cmp ecx, 1024
    jb .loop

    ; setup page directory
    mov eax, page_table + ADDRESS_KERNEL
    and eax, 0xfffff000
    or eax, 3
    mov [page_directory + ADDRESS_KERNEL], eax

    ; Enable paging
    mov eax, page_directory + ADDRESS_KERNEL
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ret

;
; Allocate memory
; in
;  eax: Requested amount in bytes
; out
;  edi: Reserved region
memory_allocate:
    mov edi, [heap_pointer]
    add [heap_pointer], eax
    ret

heap:
