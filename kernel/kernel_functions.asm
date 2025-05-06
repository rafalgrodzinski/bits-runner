cpu 386
bits 16

%define SEGMENT_SIZE 0xFFFF
%define MAX_APPS_COUNT 8

loaded_apps_count db 0

;
; Address for executable
; out
;  ax - Segment address to use for the new executable
address_for_executable:
    push bx

    cmp byte [loaded_apps_count], MAX_APPS_COUNT
    jb .start_execution
    mov ax, msg_error_execution
    call fatal_error

.start_execution:
        inc byte [loaded_apps_count] ; +1 for kernel at start
        mov ax, [loaded_apps_count]
        mov bx, SEGMENT_SIZE >> 4
        mul bx
        add ax, SEGMENT_KERNEL ; Calculate app's segment

    pop bx
    ret

;
; Execute a binary 
; in
;  ax - Address of a loaded executable
sys_execute:
    pusha

    ; Setup segments
    cli
    mov ds, ax
    sti

    ; Make a far jumpt to eax:0
    push ax
    push 0
    retf

    popa
    ret
