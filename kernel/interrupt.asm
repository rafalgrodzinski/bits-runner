cpu 386
bits 16

%include "kernel/constants.asm"

;
; Initialize the interrupt service
interrupt_init:
    pusha

    cli
    mov ax, 0
    mov es, ax
    mov word es:[SYS_INT * 4], interrupt_handler
    mov word es:[SYS_INT * 4 + 2], SEGMENT_KERNEL
    sti

    popa
    ret

;
; Interrupt handler routine
interrupt_handler:
    push ds
    push ax
    mov ax, SEGMENT_KERNEL
    mov ds, ax
    pop ax

    cmp ah, SYS_INT_PRINT_CHAR
    je int_handler_print_char

    cmp ah, SYS_INT_PRINT_STRING
    je int_handler_print_string

    cmp ah, SYS_INT_PRINT_HEX
    je int_handler_print_hex

    cmp ah, SYS_INT_GET_KEYSTROKE
    je int_handler_get_keystroke

    cmp ah, SYS_INT_CLEAR_SCREEN
    je int_handler_clear_screen

    cmp ah, SYS_INT_REBOOT
    je int_handler_reboot

    ; Default case
    mov si, msg_error_invalid_interrupt
    call fatal_error
    pop ds
    iret

;
; Print a single character
; in
;  al - Character to print
int_handler_print_char:
    call print_character
    pop ds
    iret

;
; Print a `\0` terminated string
; in
;  es:si - String address
int_handler_print_string:
    mov ax, es
    mov ds, ax
    call print_string
    pop ds
    iret

int_handler_print_hex:
    mov ax, bx
    call print_hex
    pop ds
    iret

;
; Get a keyboard press
; out
;  al - Pressed key
int_handler_get_keystroke:
    call get_keystroke
    pop ds
    iret

int_handler_clear_screen:
    call terminal_clear_screen
    pop ds
    iret

int_handler_reboot:
    call reboot
    pop ds
    iret