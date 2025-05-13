cpu 386
bits 32

%define PIC1_CMD_PORT 0x20
%define PIC1_DATA_PORT 0x21
%define PIC2_CMD_PORT 0xa0
%define PIC2_DATA_PORT 0xa1

;
; IDT (Interrupt Descriptor Table)

; IDT v86 mode (maps to BIOS IVT)
idt_descriptor_v86_mode:
dw 0x3ff
dd 0

; IDT protected mode
idt_descriptor_protected_mode:
dw idt_protected_mode_end - idt_protected_mode - 1 ; size of IDT
dd idt_protected_mode + ADDRESS_KERNEL

%macro IDT_ENTRY 2
    dw %1 ; offset, low s
    dw %2 ; segment
    db 0 ; reserved
    db 10001110b ; <7 P><5:6 DPL>4 0<3 D><0:2 Type> P - is active, DPL - priviledge, D - is 32bit, Type - 110 interrupt
    dw 0 ; offset, high s
%endmacro

idt_protected_mode:
IDT_ENTRY interrupt_handler_00 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; divide error
IDT_ENTRY interrupt_handler_01 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; debug exception
IDT_ENTRY interrupt_handler_02 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; nmi interrupt
IDT_ENTRY interrupt_handler_03 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; breakpoint
IDT_ENTRY interrupt_handler_04 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; overflow
IDT_ENTRY interrupt_handler_05 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; bound range
IDT_ENTRY interrupt_handler_06 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; invalid opcode
IDT_ENTRY interrupt_handler_07 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; no math coprocessor
IDT_ENTRY interrupt_handler_08 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; double fault
IDT_ENTRY interrupt_handler_09 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; coprocessor segment overrun
IDT_ENTRY interrupt_handler_0a + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; invalid tss
IDT_ENTRY interrupt_handler_0b + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; segment not present
IDT_ENTRY interrupt_handler_0c + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; stack-segment fault
IDT_ENTRY interrupt_handler_0d + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; general protection
IDT_ENTRY interrupt_handler_0e + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; page fault
IDT_ENTRY 0, 0 ; 0x0f
IDT_ENTRY interrupt_handler_10 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; fpu fault
IDT_ENTRY interrupt_handler_11 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; alignment check
IDT_ENTRY interrupt_handler_12 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; machine check
IDT_ENTRY interrupt_handler_13 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; simd exception
IDT_ENTRY interrupt_handler_14 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; virtualization exception
IDT_ENTRY interrupt_handler_15 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; control protection exception
IDT_ENTRY 0, 0 ; 0x16 reserved
IDT_ENTRY 0, 0 ; 0x17 reserved
IDT_ENTRY 0, 0 ; 0x18 reserved
IDT_ENTRY 0, 0 ; 0x19 reserved
IDT_ENTRY 0, 0 ; 0x1a reserved
IDT_ENTRY 0, 0 ; 0x1b reserved
IDT_ENTRY 0, 0 ; 0x1c reserved
IDT_ENTRY 0, 0 ; 0x1d reserved
IDT_ENTRY 0, 0 ; 0x1e reserved
IDT_ENTRY 0, 0 ; 0x1f reserved
IDT_ENTRY interrupt_handler_20 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 0
IDT_ENTRY interrupt_handler_21 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 1
IDT_ENTRY interrupt_handler_22 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 2
IDT_ENTRY interrupt_handler_23 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 3
IDT_ENTRY interrupt_handler_24 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 4
IDT_ENTRY interrupt_handler_25 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 5
IDT_ENTRY interrupt_handler_26 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 6
IDT_ENTRY interrupt_handler_27 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 7
IDT_ENTRY interrupt_handler_28 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 8
IDT_ENTRY interrupt_handler_29 + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ 9
IDT_ENTRY interrupt_handler_2a + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ a
IDT_ENTRY interrupt_handler_2b + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ b
IDT_ENTRY interrupt_handler_2c + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ c
IDT_ENTRY interrupt_handler_2d + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ d
IDT_ENTRY interrupt_handler_2e + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ e
IDT_ENTRY interrupt_handler_2f + ADDRESS_KERNEL, GDT_CODE_PROTECTED_MODE ; IRQ f
idt_protected_mode_end:

;
; Messages
msg_error_unhandled_0: db `Unhandled interrupt: \0`
msg_error_unhandled_1: db `, error: \0`
msg_error_unhandled_2: db `\n\0`

;
; Initialize the interrupt service for v86 mode
bits 16
interrupt_init_v86_mode:
    cli
    lidt [idt_descriptor_v86_mode + ADDRESS_KERNEL]
    sti
    ret

;
; Intialize the interrupt service for protected mode
bits 32
interrupt_init_protected_mode:
    cli

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

    lidt [idt_descriptor_protected_mode + ADDRESS_KERNEL]
    sti
    ret

;
; ISR for each interrupt, puts together error, int number and passes it on
interrupt_handler_00:
    push  0
    push  0x00
    jmp interrupt_handler

interrupt_handler_01:
    push  0
    push  0x01
    jmp interrupt_handler

interrupt_handler_02:
    push  0
    push  0x02
    jmp interrupt_handler

interrupt_handler_03:
    push  0
    push  0x03
    jmp interrupt_handler

interrupt_handler_04:
    push  0
    push  0x04
    jmp interrupt_handler

interrupt_handler_05:
    push  0
    push  0x05
    jmp interrupt_handler

interrupt_handler_06:
    push  0
    push  0x06
    jmp interrupt_handler

interrupt_handler_07:
    push  0
    push  0x07
    jmp interrupt_handler

db "APPLE"
interrupt_handler_08:
    ; error info pushed by CPU
    push  0x08
    jmp interrupt_handler

interrupt_handler_09:
    push  0
    push  0x09
    jmp interrupt_handler

interrupt_handler_0a:
    ; error info pushed by CPU
    push  0x0a
    jmp interrupt_handler

interrupt_handler_0b:
    ; error info pushed by CPU
    push  0x0b
    jmp interrupt_handler

interrupt_handler_0c:
    ; error info pushed by CPU
    push  0x0c
    jmp interrupt_handler

interrupt_handler_0d:
    ; error info pushed by CPU
    push  0x0d
    jmp interrupt_handler

interrupt_handler_0e:
    ; error info pushed by CPU
    push  0x0e
    jmp interrupt_handler

interrupt_handler_0f:
    push  0
    push  0x0f
    jmp interrupt_handler

interrupt_handler_10:
    push  0
    push  0x10
    jmp interrupt_handler

interrupt_handler_11:
    ; error info pushed by CPU
    push  0x11
    jmp interrupt_handler

interrupt_handler_12:
    push  0
    push  0x12
    jmp interrupt_handler

interrupt_handler_13:
    push  0
    push  0x13
    jmp interrupt_handler

interrupt_handler_14:
    push  0
    push  0x14
    jmp interrupt_handler

interrupt_handler_15:
    ; error info pushed by CPU
    push  0x15
    jmp interrupt_handler

interrupt_handler_16:
    push  0
    push  0x16
    jmp interrupt_handler

interrupt_handler_17:
    push  0
    push  0x17
    jmp interrupt_handler

interrupt_handler_18:
    push  0
    push  0x18
    jmp interrupt_handler

interrupt_handler_19:
    push  0
    push  0x19
    jmp interrupt_handler

interrupt_handler_1a:
    push  0
    push  0x1a
    jmp interrupt_handler

interrupt_handler_1b:
    push  0
    push  0x1b
    jmp interrupt_handler

interrupt_handler_1c:
    push  0
    push  0x1c
    jmp interrupt_handler

interrupt_handler_1d:
    push  0
    push  0x1d
    jmp interrupt_handler

interrupt_handler_1e:
    push  0
    push  0x1e
    jmp interrupt_handler

interrupt_handler_1f:
    push  0
    push  0x1f
    jmp interrupt_handler

interrupt_handler_20:
    push  0
    push  0x20
    jmp interrupt_handler

interrupt_handler_21:
    push  0
    push  0x21
    jmp interrupt_handler

interrupt_handler_22:
    push  0
    push  0x22
    jmp interrupt_handler

interrupt_handler_23:
    push  0
    push  0x23
    jmp interrupt_handler

interrupt_handler_24:
    push  0
    push  0x24
    jmp interrupt_handler

interrupt_handler_25:
    push  0
    push  0x25
    jmp interrupt_handler

interrupt_handler_26:
    push  0
    push  0x26
    jmp interrupt_handler

interrupt_handler_27:
    push  0
    push  0x27
    jmp interrupt_handler

interrupt_handler_28:
    push  0
    push  0x28
    jmp interrupt_handler

interrupt_handler_29:
    push  0
    push  0x29
    jmp interrupt_handler

interrupt_handler_2a:
    push  0
    push  0x2a
    jmp interrupt_handler

interrupt_handler_2b:
    push  0
    push  0x2b
    jmp interrupt_handler

interrupt_handler_2c:
    push  0
    push  0x2c
    jmp interrupt_handler

interrupt_handler_2d:
    push  0
    push  0x2d
    jmp interrupt_handler

interrupt_handler_2e:
    push  0
    push  0x2e
    jmp interrupt_handler

interrupt_handler_2f:
    push  0
    push  0x2f
    jmp interrupt_handler

;
; Aggregated handler for all interrupts
interrupt_handler:
    pop ebx
    pop ecx

    ; IRQ0 - timer
    cmp ebx, 0x20
    jne .not_timer
    call interrupt_handle_timer
    jmp .end

.not_timer:
    ; IRQ1 - keyboard
    cmp ebx, 0x21
    jne .not_keyboard
    call interrupt_handle_keyboard
    jmp .end

.not_keyboard:
    ; Unhandled interrupt
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_LIGHT

    mov esi, msg_error_unhandled_0 + ADDRESS_KERNEL
    call terminal_print_string

    call terminal_print_hex

    mov esi, msg_error_unhandled_1 + ADDRESS_KERNEL
    call terminal_print_string

    mov ebx, ecx
    call terminal_print_hex

    mov esi, msg_error_unhandled_2 + ADDRESS_KERNEL
    call terminal_print_string

.end:
    iret

interrupt_handle_timer:
    mov al, 0x20
    out PIC1_CMD_PORT, al
    ret

%define KEYBOARD_CMD_PORT 0x64
%define KEYBOARD_DATA_PORT 0x60
interrupt_handle_keyboard:
    mov al, 0x20
    out PIC1_CMD_PORT, al

    in al, KEYBOARD_CMD_PORT
    cmp al, 0
    jz .no_data

    in al, KEYBOARD_DATA_PORT
    movzx ebx, al
    mov al, TERMINAL_FOREGROUND_GRAY
    call terminal_print_hex

    mov ah, ` `
    call terminal_print_character

.no_data:
    ret
