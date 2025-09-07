cpu 386
org 0x1000

; Jump over data into strt point
bits 16
jmp 0:start ; Sets CS to 0

;
; GDT (Global Descriptor Table)
; for 32 bit protected mode and 16 bit v86 mode
gdt:
dq 0
gdt_code_protected_mode:
dw 0xffff
dw 0
db 0
db 10011010b
db 11001111b
db 0
gdt_data_protected_mode:
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
dd gdt ; address of GTD + offset to the address of the kernel

%define GDT_CODE_PROTECTED_MODE gdt_code_protected_mode - gdt
%define GDT_DATA_PROTECTED_MODE gdt_data_protected_mode - gdt
%define GDT_CODE_V86_MODE gdt_code_v86_mode - gdt
%define GDT_DATA_V86_MODE gdt_data_v86_mode - gdt

%define RAM_MIN 0x1000000

;
; Messages
msg_memory_detected0 db `RAM Detected: \0`
msg_memory_detected1 db ` Bytes\0`
msg_initializing db `Loading Kernel...\0`
msg_error_memory_low db `Error! At least 16MiB of RAM is required!\0`
msg_error_fatal db `Fatal Error!\0`

bits 16
start:
    call scan_memory

    ; Report memory detected
    mov si, msg_memory_detected0
    call print_string
    mov eax, [memory_size]
    call print_int
    mov si, msg_memory_detected1
    call print_string
    call print_new_line

    ; Check RAM size
    cmp dword [memory_size], RAM_MIN
    jge .ram_size_ok
    mov si, msg_error_memory_low
    call print_string
    call print_new_line
.h:
    jmp .h

.ram_size_ok:
    ; Initialization message
    mov si, msg_initializing
    call print_string
    call print_new_line

    cli
    ; Setup segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0xffff
    lgdt [gdt_descriptor]
    call switch_to_protected_mode

bits 32
l:
    jmp l

;
; Initialize memory maps and get memory size
bits 16
scan_memory:
    pusha

    mov ebx, 0
    mov di, memory_map

.loop:
    mov eax, 0xe820
    mov ecx, 24 ; 8 base + 8 size + 4 type
    mov edx, 0x534d4150 ; SMAP
    int 0x15
    
    ; process result
    inc byte [memory_map_entries] ; increase count of entries

    ; check if we found bigger memory limit
    cmp dword [di + 16], 2 ; check if marks unavailable regions
    je .size_not_updated
    mov eax, [di]
    add eax, [di + 8]
    cmp eax, [memory_size]
    jng .size_not_updated
    mov dword [memory_size], eax

.size_not_updated:
    add di, 24
    cmp ebx, 0 ; once ebx becomes 0, scanning has finished
    jne .loop
    
    popa
    ret

;
; Initialize 32 bit protected mode
bits 16
switch_to_protected_mode:
    cli
    ; Enable protected mode
    push eax
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    pop eax
    ; Long jump to 32 bits
    jmp GDT_CODE_PROTECTED_MODE:(.init_data_segment)

bits 32
.init_data_segment:
    ; Set protected mode 32 bit data segment
    push ax
    mov ax, GDT_DATA_PROTECTED_MODE
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    pop ax

    ;call interrupt_init_protected_mode

    ; re-enable paging if already set up
    push eax
    mov eax, cr3
    cmp eax, 0
    je .skip_paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

.skip_paging:
    pop eax
    ret
bits 32

;
; Initialize 16 bit 8086 virtual mode
bits 32
switch_to_v86_mode:
    ; clear interrupts and set real mode code segment
    cli
    jmp GDT_CODE_V86_MODE:(.init_v86_data_segment)

bits 16
.init_v86_data_segment:
    ; Change to 16 bit protected mode
    ; Set real mode data segment 0x0000 - 0xffff
    push eax
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
    pop eax

    ; Flush CPU and jumpt to 16 bit code
    jmp 0:.v86_mode

.v86_mode:
    push ax
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    pop ax

    ;call interrupt_init_v86_mode
    ret

;
; Print string
; in
;  si: string address
bits 16
print_string:
	pusha

	mov bx, 0
	mov ah, 0x0e
.loop:
	lodsb
	cmp al, 0
	jz .string_finished ; if al = 0
	int 0x10
	jmp .loop

.string_finished:
	popa
	ret

;
; Prints a new line
bits 16
print_new_line:
    pusha

	mov bx, 0
	mov ah, 0x0e

	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10

    popa
    ret


; Print integer
;  eax: integer to print
bits 16
print_int:
	pusha

	mov ecx, 0
process_digit:
	inc ecx
	mov edx, 0
	mov ebx, 10
	idiv ebx
	add dx, "0"
	push dx
	cmp eax, 0
	jnz process_digit

print_digit:
	dec ecx
	mov esi, esp
	call print_string
	pop ax
    ;add sp, 2
	cmp ecx, 0
	jnz print_digit

	popa
	ret

;%include "boot/terminal.asm"

memory_size: dd 0
memory_map_entries: db 0
memory_map: