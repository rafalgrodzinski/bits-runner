cpu 386
bits 16

; Use last 64KiB of the 640KiB region
%define STACK_SIZE 0xFFFF
%define STACK_SEGMENT (0x7FFFF - STACK_SIZE) >> 4

start:
    ; Setup segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov ax, STACK_SEGMENT
    mov ss, ax
    mov sp, STACK_SIZE

    mov ah, 0x0e
    mov al, "H"
    int 0x10
    mov al, "e"
    int 0x10
    mov al, "l"
    int 0x10
    mov al, "l"
    int 0x10
    mov al, "o"
    int 0x10
    mov al, "!"
    int 0x10


    ; Reboot after keypress
    mov ah, 0x00
    int 0x16

    jmp 0xffff:0

    hlt
.halt:
    jmp .halt
