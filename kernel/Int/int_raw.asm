[cpu 386]
[bits 32]

extern Int.handleInterrupt

%define PIC1_CMD_PORT 0x20
%define PIC1_DATA_PORT 0x21
%define PIC2_CMD_PORT 0xa0
%define PIC2_DATA_PORT 0xa1

%define GDT_CODE_PROTECTED_MODE 0x08
%define ISR_OFFSET_HIGH 0x80000000 >> 16

;
; IDT (Interrupt Descriptor Table)
idt_descriptor_protected_mode:
dw idt_protected_mode_end - idt_protected_mode - 1 ; size of IDT - 1
dd idt_protected_mode ; address of IDT

%macro IDT_ENTRY 1
    dw 0 ; ISR offset low bits <15-0>
    dw %1 ; gdt segment selector
    db 0 ; reserved
    db 10001110b ; <7: P> <6-5: DPL> <4: 0> <3: D> <2-0: Gate Type>, P: is active, DPL: priviledge, D: is 32bit, Gate Type: 110 interrupt
    dw 0 ; ISR offset high bits <31-16>
%endmacro

%macro IDT_ENTRY_USER 1
    dw 0 ; ISR offset low bits <15-0>
    dw %1 ; gdt segment selector
    db 0 ; reserved
    db 11101110b ; <7: P> <6-5: DPL> <4: 0> <3: D> <2-0: Gate Type>, P: is active, DPL: priviledge, D: is 32bit, Gate Type: 110 interrupt
    dw 0 ; ISR offset high bits <31-16>
%endmacro

idt_protected_mode:
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x00 divide error
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x01 debug exception
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x02 nmi interrupt
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x03 breakpoint
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x04 overflow
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x05 bound range
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x06 invalid opcode
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x07 no math coprocessor
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x08 double fault
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x09 coprocessor segment overrun
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x0a invalid tss
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x0b segment not present
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x0c stack-segment fault
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x0d general protection
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x0e page fault
IDT_ENTRY 0 ; 0x0f
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x10 fpu fault
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x11 alignment check
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x12 machine check
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x13 simd exception
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x14 virtualization exception
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x15 control protection exception
IDT_ENTRY 0 ; 0x16 reserved
IDT_ENTRY 0 ; 0x17 reserved
IDT_ENTRY 0 ; 0x18 reserved
IDT_ENTRY 0 ; 0x19 reserved
IDT_ENTRY 0 ; 0x1a reserved
IDT_ENTRY 0 ; 0x1b reserved
IDT_ENTRY 0 ; 0x1c reserved
IDT_ENTRY 0 ; 0x1d reserved
IDT_ENTRY 0 ; 0x1e reserved
IDT_ENTRY 0 ; 0x1f reserved
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x20 IRQ 0
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x21 IRQ 1
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x22 IRQ 2
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x23 IRQ 3
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x24 IRQ 4
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x25 IRQ 5
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x26 IRQ 6
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x27 IRQ 7
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x28 IRQ 8
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x29 IRQ 9
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2a IRQ a
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2b IRQ b
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2c IRQ c
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2d IRQ d
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2e IRQ e
IDT_ENTRY GDT_CODE_PROTECTED_MODE ; 0x2f IRQ f
IDT_ENTRY_USER GDT_CODE_PROTECTED_MODE ; 0x30 SYS
idt_protected_mode_end:

%macro UPDATE_IDT_ADDRESS 2
    mov eax, %2
    and eax, 0xffff
    mov [idt_protected_mode + 8 * %1], ax
    mov eax, %2
    shr eax, 16
    mov [idt_protected_mode + 8 * %1 + 6], ax
%endmacro

;
; Intialize the interrupt service for protected mode
global interrupt_init_protected_mode
interrupt_init_protected_mode:
    cli
    push eax

    ; setup handler addresses
    UPDATE_IDT_ADDRESS 0x00, interrupt_handler_00 ; 0x00 divide error
    UPDATE_IDT_ADDRESS 0x01, interrupt_handler_01 ; 0x01 debug exception
    UPDATE_IDT_ADDRESS 0x02, interrupt_handler_02 ; 0x02 nmi interrupt
    UPDATE_IDT_ADDRESS 0x03, interrupt_handler_03 ; 0x03 breakpoint
    UPDATE_IDT_ADDRESS 0x04, interrupt_handler_04 ; 0x04 overflow
    UPDATE_IDT_ADDRESS 0x05, interrupt_handler_05 ; 0x05 bound range
    UPDATE_IDT_ADDRESS 0x06, interrupt_handler_06 ; 0x06 invalid opcode
    UPDATE_IDT_ADDRESS 0x07, interrupt_handler_07 ; 0x07 no math coprocessor
    UPDATE_IDT_ADDRESS 0x08, interrupt_handler_08 ; 0x08 double fault
    UPDATE_IDT_ADDRESS 0x09, interrupt_handler_09 ; 0x09 coprocessor segment overrun
    UPDATE_IDT_ADDRESS 0x0a, interrupt_handler_0a ; 0x0a invalid tss
    UPDATE_IDT_ADDRESS 0x0b, interrupt_handler_0b ; 0x0b segment not present
    UPDATE_IDT_ADDRESS 0x0c, interrupt_handler_0c ; 0x0c stack-segment fault
    UPDATE_IDT_ADDRESS 0x0d, interrupt_handler_0d ; 0x0d general protection
    UPDATE_IDT_ADDRESS 0x0e, interrupt_handler_0e ; 0x0e page fault
    UPDATE_IDT_ADDRESS 0x10, interrupt_handler_10 ; 0x10 fpu fault
    UPDATE_IDT_ADDRESS 0x11, interrupt_handler_11 ; 0x11 alignment check
    UPDATE_IDT_ADDRESS 0x12, interrupt_handler_12 ; 0x12 machine check
    UPDATE_IDT_ADDRESS 0x13, interrupt_handler_13 ; 0x13 simd exception
    UPDATE_IDT_ADDRESS 0x14, interrupt_handler_14 ; 0x14 virtualization exception
    UPDATE_IDT_ADDRESS 0x15, interrupt_handler_15 ; 0x15 control protection exception
    UPDATE_IDT_ADDRESS 0x20, interrupt_handler_20 ; 0x20 IRQ 0
    UPDATE_IDT_ADDRESS 0x21, interrupt_handler_21 ; 0x21 IRQ 1
    UPDATE_IDT_ADDRESS 0x22, interrupt_handler_22 ; 0x22 IRQ 2
    UPDATE_IDT_ADDRESS 0x23, interrupt_handler_23 ; 0x23 IRQ 3
    UPDATE_IDT_ADDRESS 0x24, interrupt_handler_24 ; 0x24 IRQ 4
    UPDATE_IDT_ADDRESS 0x25, interrupt_handler_25 ; 0x25 IRQ 5
    UPDATE_IDT_ADDRESS 0x26, interrupt_handler_26 ; 0x26 IRQ 6
    UPDATE_IDT_ADDRESS 0x27, interrupt_handler_27 ; 0x27 IRQ 7
    UPDATE_IDT_ADDRESS 0x28, interrupt_handler_28 ; 0x28 IRQ 8
    UPDATE_IDT_ADDRESS 0x29, interrupt_handler_29 ; 0x29 IRQ 9
    UPDATE_IDT_ADDRESS 0x2a, interrupt_handler_2a ; 0x2a IRQ a
    UPDATE_IDT_ADDRESS 0x2b, interrupt_handler_2b ; 0x2b IRQ b
    UPDATE_IDT_ADDRESS 0x2c, interrupt_handler_2c ; 0x2c IRQ c
    UPDATE_IDT_ADDRESS 0x2d, interrupt_handler_2d ; 0x2d IRQ d
    UPDATE_IDT_ADDRESS 0x2e, interrupt_handler_2e ; 0x2e IRQ e
    UPDATE_IDT_ADDRESS 0x2f, interrupt_handler_2f ; 0x2f IRQ f
    UPDATE_IDT_ADDRESS 0x30, interrupt_handler_30 ; 0x30 SYS

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

    pop eax
    lidt [idt_descriptor_protected_mode]
    sti
    ret
    db 0xDE, 0xAD, 0xBE, 0xEF

;
; ISR for each interrupt, puts together error, int number and passes it on
; divide error
interrupt_handler_00:
    push  0
    push 0x00
    jmp interrupt_handler

; debug exception
interrupt_handler_01:
    push  0
    push 0x01
    jmp interrupt_handler

; nmi interrupt
interrupt_handler_02:
    push  0
    push 0x02
    jmp interrupt_handler

; breakpoint
interrupt_handler_03:
    push  0
    push 0x03
    jmp interrupt_handler

; overflow
interrupt_handler_04:
    push  0
    push 0x04
    jmp interrupt_handler

; bound range
interrupt_handler_05:
    push  0
    push 0x05
    jmp interrupt_handler

; invalid opcode
interrupt_handler_06:
    push  0
    push 0x06
    jmp interrupt_handler

; no math coprocessor
interrupt_handler_07:
    push  0
    push 0x07
    jmp interrupt_handler

; double fault
interrupt_handler_08:
    ; error info pushed by CPU
    push 0x08
    jmp interrupt_handler

; coprocessor segment overrun
interrupt_handler_09:
    push  0
    push 0x09
    jmp interrupt_handler

; invalid tss
interrupt_handler_0a:
    ; error info pushed by CPU
    push 0x0a
    jmp interrupt_handler

; segment not present
interrupt_handler_0b:
    ; error info pushed by CPU
    push 0x0b
    jmp interrupt_handler

; stack-segment fault
interrupt_handler_0c:
    ; error info pushed by CPU
    push 0x0c
    jmp interrupt_handler

; general protection
interrupt_handler_0d:
    ; error info pushed by CPU
    push 0x0d
    jmp interrupt_handler

; page fault
interrupt_handler_0e:
    ; error info pushed by CPU
    push 0x0e
    jmp interrupt_handler

; fpu fault
interrupt_handler_10:
    push  0
    push 0x10
    jmp interrupt_handler

; alignment check
interrupt_handler_11:
    ; error info pushed by CPU
    push 0x11
    jmp interrupt_handler

; machine check
interrupt_handler_12:
    push  0
    push 0x12
    jmp interrupt_handler

; simd exception
interrupt_handler_13:
    push  0
    push 0x13
    jmp interrupt_handler

; virtualization exception
interrupt_handler_14:
    push  0
    push 0x14
    jmp interrupt_handler

; control protection exception
interrupt_handler_15:
    ; error info pushed by CPU
    push 0x15
    jmp interrupt_handler

interrupt_handler_16:
    push  0
    push 0x16
    jmp interrupt_handler

interrupt_handler_17:
    push  0
    push 0x17
    jmp interrupt_handler

interrupt_handler_18:
    push  0
    push 0x18
    jmp interrupt_handler

interrupt_handler_19:
    push  0
    push 0x19
    jmp interrupt_handler

interrupt_handler_1a:
    push  0
    push 0x1a
    jmp interrupt_handler

interrupt_handler_1b:
    push  0
    push 0x1b
    jmp interrupt_handler

interrupt_handler_1c:
    push  0
    push 0x1c
    jmp interrupt_handler

interrupt_handler_1d:
    push  0
    push 0x1d
    jmp interrupt_handler

interrupt_handler_1e:
    push  0
    push 0x1e
    jmp interrupt_handler

interrupt_handler_1f:
    push  0
    push 0x1f
    jmp interrupt_handler

; IRQ 0
interrupt_handler_20:
    push 0
    push 0x20
    jmp interrupt_handler

; IRQ 1
interrupt_handler_21:
    push 0
    push 0x21
    jmp interrupt_handler

; IRQ 2
interrupt_handler_22:
    push  0
    push 0x22
    jmp interrupt_handler

; IRQ 3
interrupt_handler_23:
    push  0
    push 0x23
    jmp interrupt_handler

; IRQ 4
interrupt_handler_24:
    push  0
    push 0x24
    jmp interrupt_handler

; IRQ 5
interrupt_handler_25:
    push  0
    push 0x25
    jmp interrupt_handler

; IRQ 6
interrupt_handler_26:
    push  0
    push 0x26
    jmp interrupt_handler

; IRQ 7
interrupt_handler_27:
    push  0
    push 0x27
    jmp interrupt_handler

; IRQ 8
interrupt_handler_28:
    push  0
    push 0x28
    jmp interrupt_handler

; IRQ 9
interrupt_handler_29:
    push  0
    push 0x29
    jmp interrupt_handler

; IRQ a
interrupt_handler_2a:
    push  0
    push 0x2a
    jmp interrupt_handler

; IRQ b
interrupt_handler_2b:
    push  0
    push 0x2b
    jmp interrupt_handler

; IRQ c
interrupt_handler_2c:
    push  0
    push 0x2c
    jmp interrupt_handler

; IRQ d
interrupt_handler_2d:
    push  0
    push 0x2d
    jmp interrupt_handler

; IRQ e
interrupt_handler_2e:
    push  0
    push 0x2e
    jmp interrupt_handler

; IRQ f
interrupt_handler_2f:
    push  0
    push 0x2f
    jmp interrupt_handler

; SYS
interrupt_handler_30:
    push 0
    push 0x30
    jmp interrupt_handler

;
; Aggregated handler for all interrupts
; iret stack frame registers are arranged as follows:
; gs, fs, es, ds
; edi, esi, ebp, esp, ebx, edx, ecx, eax
%define .eax [ebp + 4 * 7]
%define .ebx [ebp + 4 * 4]
%define .ecx [ebp + 4 * 6]
%define .edx [ebp + 4 * 5]
%define .interrupt [ebp + 4 * 8]
%define .info [ebp + 4 * 9]
interrupt_handler:
    cli
    pushad
    mov ebp, esp

    push dword .info
    push dword .interrupt
    push dword .edx
    push dword .ecx
    push dword .ebx
    push dword .eax

    call Int.handleInterrupt
    mov .eax, eax

    ; Acknowledge interrupt
    mov al, 0x20
    out PIC1_CMD_PORT, al

    mov esp, ebp
    popad
    add esp, 8
    sti
    iret
%undef .info
%undef .interrupt 
%undef .ebx
%undef .eax
