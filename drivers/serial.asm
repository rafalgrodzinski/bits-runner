org 0x80000000
cpu 386
bits 32

%define COM_PORT_1 0x03f8
%define COM_PORT_2 0x02f8

%macro OUTB 2
    push dx
    mov dx, %1
    mov al, %2
    out dx, al
    pop dx
%endmacro

serial_init:
    OUTB COM_PORT_1 + 1, 0x00 ; Disable all interrupts
    OUTB COM_PORT_1 + 3, 0x80 ; Enable DLAB (set baud rate divisor)
    OUTB COM_PORT_1 + 0, 0x03 ; Set divisor to 3 (lo byte) 38400 baud
    OUTB COM_PORT_1 + 1, 0x00 ;                  (hi byte)
    OUTB COM_PORT_1 + 3, 0x03 ; 8 bits, no parity, one stop bit
    OUTB COM_PORT_1 + 2, 0xc7 ; Enable FIFO, clear them, with 14-byte threshold
    OUTB COM_PORT_1 + 4, 0x0b ; IRQs enabled, RTS/DSR set
    OUTB COM_PORT_1 + 4, 0x0f ; IRQs enabled and OUT#1 and OUT#2 bits enabled

    ret

;
; in
;  al: byte to send
serial_send_byte:
    OUTB COM_PORT_1, al
    ret

;
; in
;  eax, number to send
serial_send_hex:
    pusha

    mov ecx, 0 ; Count number of digits
.loop_process_digit:
    inc ecx
    mov edx, 0
    mov esi, 16
    div esi

    cmp edx, 10 ; Check if we should add `0` or `A`
    jae .above_9
    add edx, `0`
    jmp .digit_converted

.above_9:
    add edx, `a` - 10

.digit_converted:
    push edx ; Place converted digit on stack

    cmp eax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

    ; First print the prefix
    mov al, `0`
    call serial_send_byte
    mov al, `x`
    call serial_send_byte

    ; Check if we have even numbr of digits, if not append one
    test ecx, 0x01
    je .loop_print_digit
    mov al, `0`
    call serial_send_byte

.loop_print_digit:
    pop eax
    call serial_send_byte

    dec ecx
    jnz .loop_print_digit

    popa
    ret