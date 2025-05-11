cpu 386

bits 16
jmp start

%include "kernel/constants.asm"

;
; GDT
gdt:
dq 0
gdt_code:
dw 0xffff
dw 0
db 0
db 10011010b
db 11001111b
db 0
gdt_data:
dw 0xffff
dw 0
db 0
db 10010010b
db 11001111b
db 0
gdt_code_v86_mode:
dw 0xffff ;limit
dw 0
db 0 ; reserved
db 10011010b
db 00001111b
db 0
gdt_data_v86_mode:
dw 0xffff
dw 0
db 0
db 10010010b
db 00001111b
db 0

gdt_descriptor:
dw $ - gdt - 1 ; size of GDT - 1
dd gdt + ADDRESS_KERNEL ; address of GTD + offset to the address of the kernel

%define GDT_CODE gdt_code - gdt
%define GDT_DATA gdt_data - gdt
%define GDT_CODE_V86_MODE gdt_code_v86_mode - gdt
%define GDT_DATA_V86_MODE gdt_data_v86_mode - gdt

;
; IDT
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

idt_descriptor:
dw $ - idt - 1 ; size of IDT
dd idt + ADDRESS_KERNEL

idt_descriptor_v86_mode:
dw 0x3ff
dd 0

;
; Predefined messages
msg_welcome db `Initializing Kernel...\n\0`
msg_error_fatal db `Fatal Error!\n\0`
msg_all_done db `All done\n\0`
;msg_error_invalid_interrupt db `Invalid Interrupt!\n\0`
;msg_error_execution db `Max executables reached!\n\0`

;
; Data
;shell_file_name db `SHELL   BIN`

;
; Allocated data
;segment_app_shell resw 1

start:
    ; Setup data segment
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, ADDRESS_STACK

    ; Load global descriptor table
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Long jump to 32 bits
    jmp GDT_CODE:(start_protected_mode + ADDRESS_KERNEL)

bits 32



start_protected_mode:
    ; Load interrupts
    lidt [idt_descriptor]

    ; Setup segments
    mov ax, GDT_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    sti

    call terminal_init

    ; Welcome message
    mov esi, msg_welcome + 0x1000
    mov al, TERMINAL_FOREGROUND_BLACK + TERMINAL_BACKGROUND_WHITE
    call terminal_print_string

    call sys_switch_to_v86_mode

bits 16
next:    
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    mov ax, 0xa000
    mov es, ax
    mov ax, 0x5387
    mov es:800, ax
    mov es:12500, ax
    mov es:4400, ax

.l:
jmp .l

;
; Initialize 8086 virtual mode
bits 32
sys_switch_to_v86_mode:
    ; clear interrupts and set real mode code segment
    cli
    jmp GDT_CODE_V86_MODE:(.init_v86_data_segment + ADDRESS_KERNEL)

bits 16
.init_v86_data_segment:
    ; Change to 16 bit protected mode
    ; Set real mode data segment 0x0000 - 0xffff
    mov ax, GDT_DATA_V86_MODE
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Change to 16 bit real
    ; Clear PE flag
    mov eax, cr0
    and eax, 0xfffe
    mov cr0, eax

    ; Flush CPU and jumpt to 16 bit code
    jmp 0:.v86_mode + ADDRESS_KERNEL

.v86_mode:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Load and enable 16 bit interrupts
    lidt [idt_descriptor_v86_mode + ADDRESS_KERNEL]
    sti
    ret

;iret
    cli
    ;lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp GDT_CODE:(back + ADDRESS_KERNEL)
    .l2:
    jmp .l2


bits 32
back:
    mov ax, GDT_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ;lgdt [gdt_descriptor]
    lidt [idt_descriptor + ADDRESS_KERNEL]

    ;mov esp, ADDRESS_STACK
    ;sti

    mov esi, msg_all_done + ADDRESS_KERNEL
    mov al, TERMINAL_FOREGROUND_BROWN
    call terminal_print_string

    ;mov esi, msg_welcome + 0x1000
    ;mov al, TERMINAL_FOREGROUND_BLUE + TERMINAL_BACKGROUND_RED
    ;call terminal_print_string

    ;int 13

    .l:
    jmp .l
;
; Default interrupt handler
interrupt_handler:
    mov esi, msg_error_fatal + 0x1000
    call fatal_error

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

bits 32
;
; Stop execution and show error message
; in
;  esi: string address
fatal_error:
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_BLINKING
	call terminal_print_string
	hlt
.halt:
	jmp .halt

;
; Reboot the system
reboot:
    jmp 0xffff:0

;
; Execute a binary 
; in
;  es: Segment with loaded executable
sys_execute:
    pusha

    ; Setup segments
    cli
    mov ax, es
    mov ds, ax
    sti

    ; Make a far jumpt to es:0
    push es
    push 0
    retf

    popa
    ret

;%include "kernel/fat12.asm"
;%include "kernel/interrupt.asm"
%include "kernel/terminal.asm"
;%include "kernel/memory_manager.asm"

