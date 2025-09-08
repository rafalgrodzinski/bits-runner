org 0x200000
cpu 386
bits 32

%include "drivers/keyboard.asm"
%include "drivers/serial.asm"

%define PIC1_CMD_PORT 0x20
%define PIC1_DATA_PORT 0x21
%define PIC2_CMD_PORT 0xa0
%define PIC2_DATA_PORT 0xa1

%define GDT_CODE_PROTECTED_MODE 0x08
%define ISR_OFFSET_HIGH 0x200000 >> 16

;
; IDT (Interrupt Descriptor Table)
idt_descriptor_protected_mode:
dw idt_protected_mode_end - idt_protected_mode - 1 ; size of IDT - 1
dd idt_protected_mode ; address of IDT

%macro IDT_ENTRY 3
    dw %1 ; ISR offset low bits <0-15>
    dw %2 ; gdt segment selector
    db 0 ; reserved
    db 10001110b ; <7: P> <6-5: DPL> <4: 0> <3: D> <2-0: Gate Type>, P: is active, DPL: priviledge, D: is 32bit, Gate Type: 110 interrupt
    dw %3 ; ISR offset high bits <16-31>
%endmacro

idt_protected_mode:
IDT_ENTRY interrupt_handler_00, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x00 divide error
IDT_ENTRY interrupt_handler_01, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x01 debug exception
IDT_ENTRY interrupt_handler_02, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x02 nmi interrupt
IDT_ENTRY interrupt_handler_03, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x03 breakpoint
IDT_ENTRY interrupt_handler_04, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x04 overflow
IDT_ENTRY interrupt_handler_05, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x05 bound range
IDT_ENTRY interrupt_handler_06, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x06 invalid opcode
IDT_ENTRY interrupt_handler_07, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x07 no math coprocessor
IDT_ENTRY interrupt_handler_08, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x08 double fault
IDT_ENTRY interrupt_handler_09, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x09 coprocessor segment overrun
IDT_ENTRY interrupt_handler_0a, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x0a invalid tss
IDT_ENTRY interrupt_handler_0b, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x0b segment not present
IDT_ENTRY interrupt_handler_0c, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x0c stack-segment fault
IDT_ENTRY interrupt_handler_0d, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x0d general protection
IDT_ENTRY interrupt_handler_0e, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x0e page fault
IDT_ENTRY 0, 0, 0 ; 0x0f
IDT_ENTRY interrupt_handler_10, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x10 fpu fault
IDT_ENTRY interrupt_handler_11, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x11 alignment check
IDT_ENTRY interrupt_handler_12, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x12 machine check
IDT_ENTRY interrupt_handler_13, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x13 simd exception
IDT_ENTRY interrupt_handler_14, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x14 virtualization exception
IDT_ENTRY interrupt_handler_15, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x15 control protection exception
IDT_ENTRY 0, 0, 0 ; 0x16 reserved
IDT_ENTRY 0, 0, 0 ; 0x17 reserved
IDT_ENTRY 0, 0, 0 ; 0x18 reserved
IDT_ENTRY 0, 0, 0 ; 0x19 reserved
IDT_ENTRY 0, 0, 0 ; 0x1a reserved
IDT_ENTRY 0, 0, 0 ; 0x1b reserved
IDT_ENTRY 0, 0, 0 ; 0x1c reserved
IDT_ENTRY 0, 0, 0 ; 0x1d reserved
IDT_ENTRY 0, 0, 0 ; 0x1e reserved
IDT_ENTRY 0, 0, 0 ; 0x1f reserved
IDT_ENTRY interrupt_handler_20, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x20 IRQ 0
IDT_ENTRY interrupt_handler_21, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x21 IRQ 1
IDT_ENTRY interrupt_handler_22, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x22 IRQ 2
IDT_ENTRY interrupt_handler_23, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x23 IRQ 3
IDT_ENTRY interrupt_handler_24, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x24 IRQ 4
IDT_ENTRY interrupt_handler_25, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x25 IRQ 5
IDT_ENTRY interrupt_handler_26, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x26 IRQ 6
IDT_ENTRY interrupt_handler_27, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x27 IRQ 7
IDT_ENTRY interrupt_handler_28, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x28 IRQ 8
IDT_ENTRY interrupt_handler_29, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x29 IRQ 9
IDT_ENTRY interrupt_handler_2a, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2a IRQ a
IDT_ENTRY interrupt_handler_2b, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2b IRQ b
IDT_ENTRY interrupt_handler_2c, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2c IRQ c
IDT_ENTRY interrupt_handler_2d, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2d IRQ d
IDT_ENTRY interrupt_handler_2e, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2e IRQ e
IDT_ENTRY interrupt_handler_2f, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x2f IRQ f
IDT_ENTRY interrupt_handler_30, GDT_CODE_PROTECTED_MODE, ISR_OFFSET_HIGH ; 0x30 SYS
idt_protected_mode_end:

;
; Messages
msg_error_unhandled_0: db `Unhandled interrupt: \0`
msg_error_unhandled_1: db `, error: \0`
msg_error_unhandled_2: db `\n\0`

msg_error_page_fault_0: db `Page fault accessing memroy at: \0`
msg_error_page_fault_1: db ` !!!\n\0`

;
; Intialize the interrupt service for protected mode
interrupt_init_protected_mode:
    cli
    push ax

    ; ICW1, initialize
    mov al, 0x11
    out PIC1_CMD_PORT, al
    out PIC2_CMD_PORT, al

    ; ICW2, set IDT offsets
    mov al, 0x20 ; IDT offset
    out PIC1_DATA_PORT, al
    mov al, 0x28 ; IDT offset
    out PIC2_DATA_PORT, al

    ; ICW3
    mov al, 0x04 ; accept PIC2 on IRQ2
    out PIC1_DATA_PORT, al
    mov al, 0x02 ; mark as secondary
    out PIC2_DATA_PORT, al

    ; ICW4, set 8086 mode
    mov al, 0x01
    out PIC1_DATA_PORT, al
    out PIC2_DATA_PORT, al

    ; unmask IRQs
    mov al, 0x00
    out PIC1_DATA_PORT, al
    out PIC2_DATA_PORT, al

    pop ax
    lidt [idt_descriptor_protected_mode]
    sti
    ret
    db 0xDE, 0xAD, 0xBE, 0xEF

;
; ISR for each interrupt, puts together error, int number and passes it on
; divide error
interrupt_handler_00:
    push  0
    push eax
    mov eax, 0x00
    jmp interrupt_handler

; debug exception
interrupt_handler_01:
    push  0
    push eax
    mov eax, 0x01
    jmp interrupt_handler

; nmi interrupt
interrupt_handler_02:
    push  0
    push eax
    mov eax, 0x02
    jmp interrupt_handler

; breakpoint
interrupt_handler_03:
    push  0
    push eax
    mov eax, 0x03
    jmp interrupt_handler

; overflow
interrupt_handler_04:
    push  0
    push eax
    mov eax, 0x04
    jmp interrupt_handler

; bound range
interrupt_handler_05:
    push  0
    push eax
    mov eax, 0x05
    jmp interrupt_handler

; invalid opcode
interrupt_handler_06:
    push  0
    push eax
    mov eax, 0x06
    jmp interrupt_handler

; no math coprocessor
interrupt_handler_07:
    push  0
    push eax
    mov eax, 0x07
    jmp interrupt_handler

; double fault
interrupt_handler_08:
    ; error info pushed by CPU
    push eax
    mov eax, 0x08
    jmp interrupt_handler

; coprocessor segment overrun
interrupt_handler_09:
    push  0
    push eax
    mov eax, 0x09
    jmp interrupt_handler

; invalid tss
interrupt_handler_0a:
    ; error info pushed by CPU
    push eax
    mov eax, 0x0a
    jmp interrupt_handler

; segment not present
interrupt_handler_0b:
    ; error info pushed by CPU
    push eax
    mov eax, 0x0b
    jmp interrupt_handler

; stack-segment fault
interrupt_handler_0c:
    ; error info pushed by CPU
    push eax
    mov eax, 0x0c
    jmp interrupt_handler

; general protection
interrupt_handler_0d:
    ; error info pushed by CPU
    push eax
    mov eax, 0x0d
    jmp interrupt_handler

; page fault
interrupt_handler_0e:
    ; error info pushed by CPU
    push eax
    mov eax, 0x0e
    jmp interrupt_handler

interrupt_handler_0f:
    push  0
    push eax
    mov eax, 0x0f
    jmp interrupt_handler

; fpu fault
interrupt_handler_10:
    push  0
    push eax
    mov eax, 0x10
    jmp interrupt_handler

; alignment check
interrupt_handler_11:
    ; error info pushed by CPU
    push eax
    mov eax, 0x11
    jmp interrupt_handler

; machine check
interrupt_handler_12:
    push  0
    push eax
    mov eax, 0x12
    jmp interrupt_handler

; simd exception
interrupt_handler_13:
    push  0
    push eax
    mov eax, 0x13
    jmp interrupt_handler

; virtualization exception
interrupt_handler_14:
    push  0
    push eax
    mov eax, 0x14
    jmp interrupt_handler

; control protection exception
interrupt_handler_15:
    ; error info pushed by CPU
    push eax
    mov eax, 0x15
    jmp interrupt_handler

interrupt_handler_16:
    push  0
    push eax
    mov eax, 0x16
    jmp interrupt_handler

interrupt_handler_17:
    push  0
    push eax
    mov eax, 0x17
    jmp interrupt_handler

interrupt_handler_18:
    push  0
    push eax
    mov eax, 0x18
    jmp interrupt_handler

interrupt_handler_19:
    push  0
    push eax
    mov eax, 0x19
    jmp interrupt_handler

interrupt_handler_1a:
    push  0
    push eax
    mov eax, 0x1a
    jmp interrupt_handler

interrupt_handler_1b:
    push  0
    push eax
    mov eax, 0x1b
    jmp interrupt_handler

interrupt_handler_1c:
    push  0
    push eax
    mov eax, 0x1c
    jmp interrupt_handler

interrupt_handler_1d:
    push  0
    push eax
    mov eax, 0x1d
    jmp interrupt_handler

interrupt_handler_1e:
    push  0
    push eax
    mov eax, 0x1e
    jmp interrupt_handler

interrupt_handler_1f:
    push  0
    push eax
    mov eax, 0x1f
    jmp interrupt_handler

; IRQ 0
interrupt_handler_20:
    push 0
    push eax
    mov eax, 0x20
    jmp interrupt_handler

; IRQ 1
interrupt_handler_21:
    push 0
    push eax
    mov eax, 0x21
    jmp interrupt_handler

; IRQ 2
interrupt_handler_22:
    push  0
    push eax
    mov eax, 0x22
    jmp interrupt_handler

; IRQ 3
interrupt_handler_23:
    push  0
    push eax
    mov eax, 0x23
    jmp interrupt_handler

; IRQ 4
interrupt_handler_24:
    push  0
    push eax
    mov eax, 0x24
    jmp interrupt_handler

; IRQ 5
interrupt_handler_25:
    push  0
    push eax
    mov eax, 0x25
    jmp interrupt_handler

; IRQ 6
interrupt_handler_26:
    push  0
    push eax
    mov eax, 0x26
    jmp interrupt_handler

; IRQ 7
interrupt_handler_27:
    push  0
    push eax
    mov eax, 0x27
    jmp interrupt_handler

; IRQ 8
interrupt_handler_28:
    push  0
    push eax
    mov eax, 0x28
    jmp interrupt_handler

; IRQ 9
interrupt_handler_29:
    push  0
    push eax
    mov eax, 0x29
    jmp interrupt_handler

; IRQ a
interrupt_handler_2a:
    push  0
    push eax
    mov eax, 0x2a
    jmp interrupt_handler

; IRQ b
interrupt_handler_2b:
    push  0
    push eax
    mov eax, 0x2b
    jmp interrupt_handler

; IRQ c
interrupt_handler_2c:
    push  0
    push eax
    mov eax, 0x2c
    jmp interrupt_handler

; IRQ d
interrupt_handler_2d:
    push  0
    push eax
    mov eax, 0x2d
    jmp interrupt_handler

; IRQ e
interrupt_handler_2e:
    push  0
    push eax
    mov eax, 0x2e
    jmp interrupt_handler

; IRQ f
interrupt_handler_2f:
    push  0
    push eax
    mov eax, 0x2f
    jmp interrupt_handler

; SYS
interrupt_handler_30:
    push 0
    push eax
    mov eax, 0x30
    jmp interrupt_handler

;
; Aggregated handler for all interrupts
interrupt_handler:
cli
    ; Acknowledge interrupt
    push eax
    mov al, 0x20
    out PIC1_CMD_PORT, al
    pop eax

    ; Page fault
    cmp eax, 0x0e
    jne .not_page_fault

    call interrupt_handle_page_fault
    ; no return
.not_page_fault:

    ; IRQ0 - timer
    cmp eax, 0x20
    jne .not_timer

    call interrupt_handle_timer
    pop eax
    jmp .interrupt_handled
.not_timer:

    ; IRQ1 - keyboard
    cmp eax, 0x21
    jne .not_keyboard
    ;call keyboard_interrupt_handler
    pop eax
    jmp .interrupt_handled
.not_keyboard:

    ; SYS
    cmp eax, SYS_INT
    jne .not_sys

    pop eax
    ;call interrupt_handle_sys
    jmp .interrupt_handled
.not_sys:

    ; Unhandled interrupt
    push ebx
    push esi
    mov ebx, eax
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_LIGHT

    mov esi, msg_error_unhandled_0
    call terminal_print_string

    call terminal_print_hex

    mov esi, msg_error_unhandled_1
    call terminal_print_string

    mov ebx, [esp + 12]
    call terminal_print_hex

    mov esi, msg_error_unhandled_2
    call terminal_print_string

    pop esi
    pop ebx
    pop eax
    add esp, 4
    jmp .end

.interrupt_handled:
    add esp, 4 ; Pop error code

.end:
    sti
    iret

;
; Page fault
interrupt_handle_page_fault:
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_BLINKING
    mov esi, msg_error_page_fault_0
    call terminal_print_string

    mov ebx, cr2
    call terminal_print_hex

    mov esi, msg_error_page_fault_1
    call terminal_print_string
.halt:
    hlt
    jmp .halt


interrupt_handle_timer:
    ret

;
; Handle syscall
interrupt_handle_sys:
    ; Print char
    cmp ah, SYS_INT_PRINT_CHAR
    jne .not_print_char
    push eax
    mov ah, bl
    call terminal_print_character
    pop eax
    jmp .end

.not_print_char:
    ; Print string
    cmp ah, SYS_INT_PRINT_STRING
    jne .not_print_string
    call terminal_print_string
    jmp .end

.not_print_string:
    ; Print hex
    cmp ah, SYS_INT_PRINT_HEX
    jne .not_print_hex
    call terminal_print_hex
    jmp .end

.not_print_hex:
    ; Get pressed ascii
    cmp ah, SYS_INT_GET_PRESSED_ASCII
    jne .not_get_pressed_ascii
    movzx ebx, byte [pressedAcii]
    mov byte [pressedAcii], 0
    jmp .end

.not_get_pressed_ascii:
    ; Reboot
;    cmp ah, SYS_INT_REBOOT
;    jne .not_reboot
;    call reboot
;
;.not_reboot:

.end:
    ret