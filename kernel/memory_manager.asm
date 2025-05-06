cpu 386
bits 16

heap_pointer resd 1
;heap_end resd 1

;
; Initialize memory manager
memory_init:
    pusha
    mov eax, ds
    shl eax, 4
    add eax, heap
    mov [heap_pointer], eax
    popa
    ret

;
; Allocate memory
; in
;  ax - Requested amount in bytes
; out
;  es - Reserved region
memory_allocate:
    push eax
    push ebx
    push edx

    push ax ; Add after calculating base pointer
    mov eax, [heap_pointer]
    mov ebx, 0x10
    div ebx
    ; Check if we're 16bit alligned, if not add 1 to the next address
    cmp edx, 0
    jz .done
    add eax, 1

.done:
    mov es, ax
    shl eax, 4
    pop bx ; Stored requested amount
    and ebx, 0xffff
    add eax, ebx
    mov [heap_pointer], eax

    pop edx
    pop ebx
    pop eax
    ret

heap:
