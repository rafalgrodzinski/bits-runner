cpu 386
bits 32

%include "boot/bios_service_header.asm"
%include "kernel/constants.asm"

jmp start

bios_service: dd 0

;
; Messages
msg_initializing db `Initializing Bits Runner...\n\0`
msg_ready db `All ready, welcome to Bits Runner!\n\0`
msg_error_fatal db `Fatal Error!\n\0`

extern mem.init

start:
    mov [bios_service], eax ; To use services provided by BIOS
    call interrupt_init_protected_mode
    call terminal_init
    ;call serial_init

    ; Initializing message
    mov esi, msg_initializing
    mov al, TERMINAL_FOREGROUND_GRAY
    call terminal_print_string

    ; Ready message
    mov esi, msg_ready
    mov al, TERMINAL_FOREGROUND_GREEN
    call terminal_print_string

    call mem.init

    ; Ready message
    mov esi, msg_ready
    mov al, TERMINAL_FOREGROUND_GREEN
    call terminal_print_string

.halt:
    hlt
    jmp .halt

;
; Stop execution and show error message
; in
;  esi: string address
sys_fatal_error:
    cli
    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_BLINKING
	call terminal_print_string
.halt:
	hlt
	jmp .halt

;
; Reboot the system
sys_reboot:
    mov ah, BIOS_SERVICE_REBOOT
    call [bios_service]

;%include "kernel/fat12.asm"
%include "kernel/interrupt.asm"
%include "kernel/terminal.asm"
;%include "kernel/memory_manager.asm"
