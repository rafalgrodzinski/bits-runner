cpu 386
bits 16

jmp start

msg_welcome db `Shell started\n\0`

start:
    mov ax, ds
    mov es, ax

    mov ah, 0x01
    mov si, msg_welcome
    int 0xff

.loop:
    mov ah, 0x02
    int 0xff

    mov ah, 0x00
    int 0xff

    jmp .loop