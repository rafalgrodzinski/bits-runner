cpu 386
bits 16

;
; Execute a binary 
; in
;  es: Segment with loaded executable
sys_execute:
    pusha

    ; Setup segments
    cli
    mov ax, es
    mov ds, ax
    sti

    ; Make a far jumpt to es:0
    push es
    push 0
    retf

    popa
    ret
