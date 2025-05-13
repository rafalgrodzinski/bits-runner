cpu 386
bits 32

heap_pointer: dd 0

;
; Initialize memory manager
memory_init:
    mov dword [heap_pointer], heap + ADDRESS_KERNEL
    ret

;
; Allocate memory
; in
;  eax - Requested amount in bytes
; out
;  edi - Reserved region
memory_allocate:
    mov edi, [heap_pointer]
    add [heap_pointer], eax
    ret

heap:
