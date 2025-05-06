cpu 386
bits 16

jmp start

%include "kernel/constants.asm"

; Use last 64KiB of the 640KiB region
%define STACK_SIZE 0xFFFF
%define STACK_SEGMENT (0x7FFFF - STACK_SIZE) >> 4

;
; Predefined messages
msg_welcome db `Initializing kernel...\n\0`, 0
msg_error_fatal db `Fatal Error!\n\0`
msg_error_invalid_interrupt db `Invalid Interrupt!\n\0`
msg_error_execution db `Max executables reached!\n\0`

;
; Data
shell_file_name db `SHELL   BIN`

;
; Allocated data
segment_app_shell resw 1

start:
    ; Setup segments
    cli
    mov ax, cs
    mov ds, ax
    mov ax, STACK_SEGMENT
    mov ss, ax
    mov sp, STACK_SIZE
    sti

    ; Welcome message
    mov si, msg_welcome
    call print_string

    call memory_init
    call interrupt_init
    call fat_init

    ; Load shell
    mov si, shell_file_name
    call fat_file_size ; returns size in ax
    call memory_allocate ; returns es:0
    mov [segment_app_shell], es
    call fat_cluster_number ; return number in ax
    call fat_load_file
    call sys_execute

    mov si, msg_error_fatal
    call fatal_error

;
; Stop execution and show error message
; in
;  si - Messge address
fatal_error:
	call print_string
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

%include "kernel/fat12.asm"
%include "kernel/interrupt.asm"
%include "kernel/terminal.asm"
%include "kernel/memory_manager.asm"
