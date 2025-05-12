cpu 386
bits 32

%include "kernel/constants.asm"

;
; IDT (Interrupt Descriptor Table)

; IDT v86 mode (map to BIOS IVT)
idt_descriptor_v86_mode:
dw 0x3ff
dd 0

; IDT protected mode
idt_descriptor_protected_mode:
dw idt_end - idt - 1 ; size of IDT
dd idt + ADDRESS_KERNEL

idt:
; 0
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 1
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 2
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 3
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 4
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 5
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 6
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 7
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 8
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 9
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 10
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 11
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 12
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 13
dw interrupt_handler_gpf + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 14
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 15
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
; 16
dw interrupt_handler + ADDRESS_KERNEL
dw 0x08
db 0
db 10001110b
dw 0
idt_end:

;
; Initialize the interrupt service for v86 mode
bits 16
interrupt_init_v86_mode:
    cli
    lidt [idt_descriptor_v86_mode + ADDRESS_KERNEL]
    sti
    ret

bits 32
interrupt_init_protected_mode:
    cli
    lidt [idt_descriptor_protected_mode + ADDRESS_KERNEL]
    sti
    ret

;
; Default interrupt handler
interrupt_handler:
    mov esi, msg_error_fatal + 0x1000
    call sys_fatal_error

msg_gpf db `GPF Handler\n\0`
interrupt_handler_gpf:
    ;mov esi, msg_gpf + ADDRESS_KERNEL
    ;mov al, TERMINAL_FOREGROUND_CYAN
    ;call terminal_print_string
    ;lidt [idt16 + ADDRESS_KERNEL]
    ; mov ah, 0x00
    ;mov al, 0x13
    ;int 0x10
    ;iret
.j:
    jmp .j
    iretd

;
; Interrupt handler routine
;interrupt_handler:
;    push ds
;    push ax
;    mov ax, SEGMENT_KERNEL
;    mov ds, ax
;    pop ax
;
;    cmp ah, SYS_INT_PRINT_CHAR
;    je int_handler_print_char
;
;    cmp ah, SYS_INT_PRINT_STRING
;    je int_handler_print_string
;
;    cmp ah, SYS_INT_PRINT_HEX
;    je int_handler_print_hex
;
;    cmp ah, SYS_INT_GET_KEYSTROKE
;    je int_handler_get_keystroke
;
;    cmp ah, SYS_INT_CLEAR_SCREEN
;    je int_handler_clear_screen
;
;    cmp ah, SYS_INT_REBOOT
;    je int_handler_reboot

    ; Default case
;    mov si, msg_error_invalid_interrupt
;    call fatal_error
;    pop ds
;    iret

;
; Print a single character
; in
;  al - Character to print
;int_handler_print_char:
;    call print_character
;    pop ds
;    iret

;
; Print a `\0` terminated string
; in
;  es:si - String address
;int_handler_print_string:
;    mov ax, es
;    mov ds, ax
;    call print_string
;    pop ds
;    iret

;int_handler_print_hex:
;    mov ax, bx
;    call print_hex
;    pop ds
;    iret

;
; Get a keyboard press
; out
;  al - Pressed key
;int_handler_get_keystroke:
;    call get_keystroke
;    pop ds
;    iret
;
;int_handler_clear_screen:
;    call terminal_clear_screen
;    pop ds
;    iret
;
;int_handler_reboot:
;    call reboot
;    pop ds
;    iret