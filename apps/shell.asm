cpu 386
bits 16

jmp start

msg_welcome db `Shell started\n\0`

start:
    mov ax, 0x00
    mov bx, msg_welcome
    int 0x20
