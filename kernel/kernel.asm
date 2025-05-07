cpu 386
bits 16

jmp start

%include "kernel/constants.asm"

;
; Predefined messages
msg_welcome db `Initializing Kernel...\n\0`
msg_error_fatal db `Fatal Error!\n\0`
;msg_error_invalid_interrupt db `Invalid Interrupt!\n\0`
;msg_error_execution db `Max executables reached!\n\0`

;
; Data
;shell_file_name db `SHELL   BIN`

;
; Allocated data
;segment_app_shell resw 1

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

gdt_descriptor:
dw $ - gdt - 1 ; size of GDT - 1
dd gdt + ADDRESS_KERNEL ; address of GTD + offset to the address of the kernel

%define GDT_CODE gdt_code - gdt
%define GDT_DATA gdt_data - gdt

start:
    ; Setup data segment
    cli
    mov ax, cs
    mov ds, ax

    ; Load global descriptor table
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Long jump to 32 bits
    jmp GDT_CODE:(start_protected_mode + ADDRESS_KERNEL)

bits 32

start_protected_mode:
    ; setup segments
    mov ax, GDT_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, ADDRESS_STACK

    call terminal_init

    ; Welcome message
    mov esi, msg_welcome + 0x1000
    mov al, TERMINAL_FOREGROUND_BLACK + TERMINAL_BACKGROUND_WHITE
    call terminal_print_string

    mov esi, msg_error_fatal + 0x1000
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_BLINKING

;
; Stop execution and show error message
; in
;  esi: string address
;  al: text attribute
fatal_error:
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

