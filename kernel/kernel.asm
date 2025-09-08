org 0x200000
cpu 386
bits 32

%include "kernel/constants.asm"

;bits 16
;jmp 0:start + ADDRESS_KERNEL ; Sets CS to 0
jmp start

;
; GDT (Global Descriptor Table)
; for 32 bit protected mode and 16 bit v86 mode
;gdt:
;dq 0
;gdt_code_protected_mode:
;dw 0xffff
;dw 0
;db 0
;db 10011010b
;db 11001111b
;db 0
;gdt_data_protected_mode:
;dw 0xffff
;dw 0
;db 0
;db 10010010b
;db 11001111b
;db 0
;gdt_code_v86_mode:
;dw 0xffff ;limit
;dw 0
;db 0 ; reserved
;db 10011010b
;db 00001111b
;db 0
;gdt_data_v86_mode:
;dw 0xffff
;dw 0
;db 0
;db 10010010b
;db 00001111b
;db 0
;
;gdt_descriptor:
;dw $ - gdt - 1 ; size of GDT - 1
;dd gdt + ADDRESS_KERNEL ; address of GTD + offset to the address of the kernel

;%define GDT_CODE_PROTECTED_MODE gdt_code_protected_mode - gdt
;%define GDT_DATA_PROTECTED_MODE gdt_data_protected_mode - gdt
;%define GDT_CODE_V86_MODE gdt_code_v86_mode - gdt
;%define GDT_DATA_V86_MODE gdt_data_v86_mode - gdt

;file_shell: db `SHELL   BIN`

;
; Messages
msg_initializing db `Initializing Bits Runner...\n\0`
msg_ready db `All ready, welcome to Bits Runner!\n\0`
msg_error_fatal db `Fatal Error!\n\0`

;bits 16
start:
    call interrupt_init_protected_mode
;    cli
;    ; Setup segments
;    mov ax, 0
;    mov ds, ax
;    mov es, ax
;    mov fs, ax
;    mov gs, ax
;    mov ss, ax
;    mov sp, ADDRESS_STACK
;    lgdt [gdt_descriptor + ADDRESS_KERNEL]
;    call sys_switch_to_protected_mode

;bits 32
    call terminal_init

    ; Initializing message
    mov esi, msg_initializing
    mov al, TERMINAL_FOREGROUND_GRAY
    call terminal_print_string

    ;call memory_init
    ;call fat_init

    ; Ready message
    mov esi, msg_ready
    mov al, TERMINAL_FOREGROUND_GREEN
    call terminal_print_string

    ; Load shell
    ;mov esi, file_shell + ADDRESS_KERNEL
    ;call fat_file_entry ; Get file entry into edi
    ;mov ebx, edi ; preserve

    ;mov esi, edi
    ;call fat_file_size ; Get size into eax
    ;call memory_allocate  ; Allocate memory into edi

    ;mov eax, 0 
    ;mov esi, ebx ; restore entry address
    ;call fat_load_file

    ;jmp edi ; start shell

.halt:
    hlt
    jmp .halt

;
; Initialize 32 bit protected mode
;bits 16
;sys_switch_to_protected_mode:
;    cli
;    ; Enable protected mode
;    push eax
;    mov eax, cr0
;    or eax, 1
;    mov cr0, eax
;    pop eax
;    ; Long jump to 32 bits
;    jmp GDT_CODE_PROTECTED_MODE:(.init_data_segment + ADDRESS_KERNEL)
;
;bits 32
;.init_data_segment:
;    ; Set protected mode 32 bit data segment
;    push ax
;    mov ax, GDT_DATA_PROTECTED_MODE
;    mov ds, ax
;    mov es, ax
;    mov fs, ax
;    mov gs, ax
;    mov ss, ax
;    pop ax
;
;    call interrupt_init_protected_mode
;
;    ; re-enable paging if already set up
;    push eax
;    mov eax, cr3
;    cmp eax, 0
;    je .skip_paging
;    mov eax, cr0
;    or eax, 0x80000000
;    mov cr0, eax
;
;.skip_paging:
;    pop eax
;    ret
;bits 32

;
; Initialize 16 bit 8086 virtual mode
;bits 32
;sys_switch_to_v86_mode:
;    ; clear interrupts and set real mode code segment
;    cli
;    jmp GDT_CODE_V86_MODE:(.init_v86_data_segment + ADDRESS_KERNEL)
;
;bits 16
;.init_v86_data_segment:
;    ; Change to 16 bit protected mode
;    ; Set real mode data segment 0x0000 - 0xffff
;    push eax
;    mov ax, GDT_DATA_V86_MODE
;    mov ds, ax
;    mov es, ax
;    mov fs, ax
;    mov gs, ax
;    mov ss, ax
;
;    ; Change to 16 bit real
;    ; Clear PE flag
;    mov eax, cr0
;    and eax, 0xfffe
;    mov cr0, eax
;    pop eax
;
;    ; Flush CPU and jumpt to 16 bit code
;    jmp 0:.v86_mode + ADDRESS_KERNEL
;
;.v86_mode:
;    push ax
;    mov ax, cs
;    mov ds, ax
;    mov es, ax
;    mov fs, ax
;    mov gs, ax
;    mov ss, ax
;    pop ax
;
;    call interrupt_init_v86_mode
;    ret
;bits 32

;
; Stop execution and show error message
; in
;  esi: string address
;sys_fatal_error:
;    cli
;    mov al, TERMINAL_FOREGROUND_RED + TERMINAL_ATTRIB_BLINKING
;	call terminal_print_string
;.halt:
;	hlt
;	jmp .halt

;
; Reboot the system
;reboot:
;    call sys_switch_to_v86_mode
;bits 16
;    jmp 0xffff:0

;%include "kernel/fat12.asm"
%include "kernel/interrupt.asm"
%include "kernel/terminal.asm"
;%include "kernel/memory_manager.asm"
