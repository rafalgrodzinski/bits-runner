[org 0x1000]
[cpu 386]

%include "bios_service/bios_service_header.asm"

%define RAM_MIN 0x1000000 ; 16MiB
%define KERNEL_PHY_ADR 0x100000 ; 1MiB
%define KERNEL_ADR 0x80000000

%define PIC1_CMD_PORT 0x20
%define PIC1_DATA_PORT 0x21
%define PIC2_CMD_PORT 0xa0
%define PIC2_DATA_PORT 0xa1

; Jump over data into strt point
[bits 16]
jmp 0:start_16 ; Sets CS to 0

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
gdt_code_user_mode:
dw 0xffff ; limit <15-0>
dw 0x00 ; base <15-0>
db 0x00 ; base <23-16>
db 11111010b ; <7: Present> <6-5: Priviledge Level> <4: 1> <3-0: Type>
db 11001111b ; <7: limit * 4kB> <6: 32bit> <5-4: 0> <3-0: limit 19-16>
db 0x00 ; base <31-24>
gdt_data_user_mode:
dw 0xffff
dw 0x00
db 0x00
db 11110010b
db 11001111b
db 0x00
gdt_tss:
dq 0

gdt_descriptor:
dw $ - gdt - 1 ; size of GDT - 1
dd gdt ; address of GTD + offset to the address of the kernel

; Already initialized protected mode IDT
idt_descriptor_protected_mode:
dw 0
dd 0

; IDT v86 mode (maps to BIOS IVT)
idt_descriptor_v86_mode:
dw 0x3ff
dd 0

; Used for checking current state
idt_descriptor_current:
dw 0
dd 0

%define GDT_CODE_PROTECTED_MODE gdt_code_protected_mode - gdt
%define GDT_DATA_PROTECTED_MODE gdt_data_protected_mode - gdt
%define GDT_CODE_V86_MODE gdt_code_v86_mode - gdt
%define GDT_DATA_V86_MODE gdt_data_v86_mode - gdt

boot_drive_number: dd 0
boot_partition_first_sector: dd 0
kernel_file_name: db `KERNEL  BIN`
kernel_size: dd 0

;
; Messages
msg_memory_detected0 db `RAM Detected: \0`
msg_memory_detected1 db ` Bytes\0`
msg_initializing db `Loading Kernel...\0`
msg_a20_enabled db `A20 line enabled\0`
msg_error_memory_low db `Fatal Error! At least 16MiB of RAM is required!\0`
msg_error_kernel_not_found db `Fatal Error! KERNEL.BIN not found!\0`
msg_error_a20_not_enabled db `Fatal Error! A20 line not enabled!\0`

;---
; Initialization
;---

[bits 16]
start_16:
    ; Setup segments and stack
    mov bx, 0
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    mov ss, bx
    mov sp, 0xffff

	; store boot drive number
    and edx, 0xff
	mov [boot_drive_number], edx

    ; store boot partition address
    and eax, 0xffff
    mov [boot_partition_first_sector], eax

    ; Set video mode to 80x25
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Enable line A20 so memory above 1MiB behaves correctly
    call enable_a20_16
    call is_a20_enabled_16
    cmp ax, 0x00
    je .a20_not_enabled

    mov si, msg_a20_enabled
    mov bl, 0
    call print_string
    call print_new_line_16
    jmp .after_a20_check

.a20_not_enabled:
    mov si, msg_error_a20_not_enabled
    mov bl, 0
    call fatal_error

.after_a20_check:

    ; Get memory size and layout
    call scan_memory_16

    ; Report memory detected
    mov si, msg_memory_detected0
    call print_string
    mov eax, [memory_size]
    call print_int
    mov si, msg_memory_detected1
    call print_string
    call print_new_line_16

    ; Check RAM size
    cmp dword [memory_size], RAM_MIN
    jge .ram_size_ok
    mov si, msg_error_memory_low
    call fatal_error ; Too little RAM!

.ram_size_ok:
    ; Initialization message
    mov si, msg_initializing
    call print_string
    call print_new_line_16

    cli
    ; Mark paging as uninitialized
    mov eax, 0x00
    mov cr3, eax
    
    ; Load GDT and switch to protected mode
    lgdt [gdt_descriptor]

    call switch_to_protected_mode
[bits 32]

    ; Initialize storage
    push dword [boot_partition_first_sector]
    push dword [boot_drive_number]
    call boot_storage_init_32

    ; Load kernel
    mov eax, 24
    mul dword [memory_map_entries_count]
    add eax, buffer
    push eax ; buffer_adr (after scanned memory map)
    push dword KERNEL_PHY_ADR ; target_adr
    push kernel_file_name ; file_name_adr
    call boot_storage_load_file_32

    .l:
    jmp .l
    ;cmp eax, 0
;    jz .kernel_file_found
;    call switch_to_v86_mode
;bits 16
;    mov si, msg_error_kernel_not_found
;    call fatal_error

;bits 32
;.kernel_file_found:
;    mov ebx, edi ; preserve
;
;    mov esi, edi
;    call fat_file_size ; Get size into eax
;    mov [kernel_size], eax
;
;    mov esi, ebx ; restore entry address
;    mov edi, KERNEL_PHY_ADR
;    mov ebx, BUFFER_ADR
;    mov dl, [boot_drive_number]
;    call fat_load_file

    ; Provide memory information to kernel
    push dword [kernel_size]
    push buffer ; memory_map_entries_adr
    push dword [memory_map_entries_count] ; memory_map_entries_count
    push dword 0x1000 ; page_size
    push dword [memory_size] ; memory_size
    add edi, [kernel_size]
    push edi ; layout_data_adr
    call init_memory_layout

    ; Enable paging
    call memory_init

    mov eax, bios_service
    mov ebx, gdt_tss
    ;mov edx, 0
    ;mov dl, [boot_drive_number]
    ;mov esi, 0
    ;mov si, [boot_partition_entry_adr]
    jmp KERNEL_ADR

.halt:
    hlt
    jmp .halt

;---
; Initialization support
;---

;
; Try enabling A20 gate so we can access 16MiB of RAM
[bits 16]
enable_a20_16:
	cli

	call is_a20_enabled_16
    cmp ax, 0x01
	je .end

	; fast a20 gate
	in al, 0x92
	or al, 2
	out 0x92, al

.end:
	sti
	ret

;
; Check if A20 line is enabled
; out
;  ax: 1 - enabled, 0 - disabled
[bits 16]
is_a20_enabled_16:
    push es
	mov ax, 0xffff
	mov es, ax
    ; boot sector indicator is loaded at 0x0000:0x7e0e
    ; check if it's wrapped at 0xffff:0x7e0e
    mov ax, [es:0x7e0e]
    cmp ax, 0xaa55
    jne .enabled

    mov ax, 0x00
    jmp .end

.enabled:
    mov ax, 0x01

.end:
    pop es
	ret

;
; Initialize memory maps and get memory size
[bits 16]
scan_memory_16:
    mov ebx, 0
    mov di, buffer

.loop:
    mov eax, 0xe820
    mov ecx, 24 ; 8 base + 8 size + 4 type
    mov edx, 0x534d4150 ; SMAP
    int 0x15
    
    ; process result
    inc byte [memory_map_entries_count] ; increase count of entries

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
    push eax
    mov ax, GDT_DATA_PROTECTED_MODE
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; re-enable paging if already set up
    mov eax, cr3
    cmp eax, 0
    je .skip_paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

.skip_paging:
    call restore_protected_mode_interrupts
    pop eax

    ret

;
; Restore interrupts for protected mode
bits 32
restore_protected_mode_interrupts:
    cli

    ; Check if protected mode interrupts are initialized
    cmp dword [idt_descriptor_protected_mode + 2], 0
    je .end ; if not, skip the restore

    push eax

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

.end:
    ret

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

    call restore_v86_mode_interrupts
    ret

;
; Restore interrupts for v86 mode
bits 16
restore_v86_mode_interrupts:
    cli

    ; Check currently active interrupts descriptor
    sidt [idt_descriptor_current]
    cmp dword [idt_descriptor_current + 2], 0
    je .end 
    sidt [idt_descriptor_protected_mode] ; otherwise store it as protected mode
    
    push eax

    ; ICW1, initialize
    mov al, 0x11
    out PIC1_CMD_PORT, al
    out PIC2_CMD_PORT, al

    ; ICW2, set IDT offsets
    mov al, 0x08 ; IDT offset
    out PIC1_DATA_PORT, al
    mov al, 0x70 ; IDT offset
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
    lidt [idt_descriptor_v86_mode]
    sti

.end:
    ret

;---
; BIOS Services
;---

;
; BIOS Services
; in
;  ah: service code
bits 32
bios_service:
    ; Reboot
    cmp ah, BIOS_SERVICE_REBOOT
    jne .not_reboot
    call reboot
.not_reboot:

    ; Video mode
    cmp ah, BIOS_SERVICE_SET_VIDEO_MODE
    jne .not_set_video_mode
    call set_video_mode
.not_set_video_mode:

    ; Read sectors
    cmp ah, BIOS_SERVICE_READ_SECTORS
    jne .not_read_sectors
    push edi ; target address
    push ecx ; number of sectors
    push ebx ; lba source address
    and eax, 0xff
    push eax ; drive number
    call service_read_sectors
.not_read_sectors:

    ; Sectors count
    cmp ah, BIOS_SERVICE_SECTORS_COUNT
    jne .not_sectors_count
    and edx, 0xff
    push edx ; drive number
    call service_sectors_count
.not_sectors_count:

    ret

;
; Reboot the system
bits 32
reboot:
    call switch_to_v86_mode
bits 16
    jmp 0xffff:0

;
; Change video mode
; in
;  al: video mode
bits 32
set_video_mode:
    call switch_to_v86_mode

bits 16
    ; text 80x25
    cmp al, BIOS_SERVICE_TEXT_MODE_80x25
    jne .not_80x25
    mov ax, 0x0003
    mov bl, 0
    int 0x10
    jmp .end
.not_80x25:

    ; text 80x50
    cmp al, BIOS_SERVICE_TEXT_MODE_80x50
    jne .not_80x50
    mov ax, 0x1112
    mov bl, 0
    int 0x10
    jmp .end
.not_80x50:

    ;graphics 320x200x8
    cmp al, BIOS_SERVICE_GPXS_MODE_320x200x8
    jne .not_320x200x8
    mov ax, 0x0013
    int 0x10
    jmp .end
.not_320x200x8:

    ;graphics 640x480x4
    cmp al, BIOS_SERVICE_GPXS_MODE_640x480x4
    jne .not_640x480x4
    mov ax, 0x0012
    int 0x10
    jmp .end
.not_640x480x4:

.end:
    call switch_to_protected_mode
bits 32
    ret

;
; Read sectors from a given device
; in
;  drive_number
;  source_lba_address
;  sectors_count
;  target_address
%define .drive_number [ebp + 8]
%define .source_lba_address [ebp + 12]
%define .sectors_count [ebp + 16]
%define .target_address [ebp + 20]
[bits 32]
service_read_sectors:
    push ebp
    mov ebp, esp

    mov ecx, 0 ; sectors counter
.loop:
    ; read one sector into a buffer
    mov eax, .source_lba_address
    add eax, ecx ; lba address
    mov ebx, 1 ; read one sector
    mov edi, buffer 
    mov dl, .drive_number
    call read_sectors

    ; copy from buffer into the target addrss
    mov ebx, 0 ; buffer bytes counter
.buffer_copy_loop:
    mov eax, 0x200
    mul ecx
    add eax, .target_address
    add eax, ebx ; calculate target address in eax

    mov dl, [buffer + ebx]
    mov byte [eax], dl ; finally copy the byte

    inc ebx
    cmp ebx, 0x200
    jb .buffer_copy_loop

    inc ecx
    cmp ecx, .sectors_count
    jb .loop

    mov esp, ebp
    pop ebp
    ret 4 * 4
%undef .target_address
%undef .sectors_count
%undef .source_lba_address
%undef .drive_number

;
; Get number of sectors for a given drive 
; in
;  drive_number
%define .drive_number [ebp + 8]
bits 32
service_sectors_count:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode
bits 16
    mov ah, 0x08
    mov edx, .drive_number
    ;mov esi, buffer
    int 0x13
    ;mov eax, [buffer + 0x10]

    ; heads
    mov eax, 0
    mov al, dh
    inc al

    ; sectors
    mov bx, cx
    and bx, 0x3f ; bits 5-0 sectors
    mul bx

    ; cylinders
    mov bx, 0
    mov bl, ch
    shr cl, 6
    mov bh, cl
    inc bx
    mul bx

    ; eax <- heads * sectors * cylinders

    call switch_to_protected_mode
bits 32

    mov esp, ebp
    pop ebp
    ret 4 * 1

;
; Stop execution and show error message
; in
;  si: string address
fatal_error:
    cli

    mov ah, 0x0e
.loop:
	lodsb
	cmp al, 0
	jz .halt ; if al = 0
	int 0x10
	jmp .loop

.halt:
    hlt
    jmp .halt

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
; Prints new line
[bits 32]
print_new_line_32:
    call switch_to_v86_mode
[bits 16]

    call print_new_line_16

    call switch_to_protected_mode
[bits 32]
    ret

;
; Prints a new line
[bits 16]
print_new_line_16:
	mov bx, 0
	mov ah, 0x0e

	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10

    ret

;
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
	mov esi, esp
	call print_string
    add sp, 2
    loop print_digit

	popa
	ret

;
; in
;  value
%define .value [ebp + 8]
[bits 32]
print_hex_32:
    push ebp
    mov ebp, esp

    mov eax, .value

    call switch_to_v86_mode
[bits 16]

    call print_hex

    call switch_to_protected_mode
[bits 32]

    mov esp, ebp
    pop ebp
    ret 4 * 1

;
; Print hexadeciaml value
; in
;  eax: integer to print
bits 16
print_hex:
    pusha

    mov ecx, 0 ; Count number of digits
.loop_process_digit:
    inc ecx
    mov edx, 0
    mov esi, 16
    div esi

    cmp dx, 10 ; Check if we should add `0` or `A`
    jae .above_9
    add dx, `0`
    jmp .digit_converted

.above_9:
    add dx, `a` - 10

.digit_converted:
    push dx ; Place converted digit on stack

    cmp eax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

    ; Check if we have even numbr of digits, if not append one
    test cx, 0x01
    je .print_pref
	push 0x0030
	inc cx

.print_pref:
	push 0x0000
	push 0x7830
	mov si, sp
	call print_string
	add sp, 4

.loop_print_digit:
	mov si, sp
	call print_string
	add sp, 2
	loop .loop_print_digit

    popa
    ret

;
; Provide memory information to kernel
; in
;  layout_data_adr
;  memory_size
;  page_size
;  memory_map_entries_count
;  memory_map_entries_adr
;  kernel_size
%define .layout_data_adr [ebp + 8]
%define .memory_size [ebp + 12]
%define .page_size [ebp + 16]
%define .memory_map_entries_count [ebp + 20]
%define .memory_map_entries_adr [ebp + 24]
%define .kernel_size [ebp + 28]
bits 32
init_memory_layout:
    push ebp
    mov ebp, esp

    sub sp, 8
    %define .current_map_entry [ebp - 0]
    %define .pages_count [ebp - 4]

    mov edi, .layout_data_adr
    mov eax, .memory_size
    mov [edi], eax ; memSize

    mov ebx, .page_size
    mov dword [edi + 4], ebx ; pageSize

    mov edx, 0x00
    div ebx
    mov [edi + 8], eax ; pagesCount
    mov .pages_count, eax

    mov dword .current_map_entry, 0
    mov esi, .memory_map_entries_adr
    mov ecx, 0
.loop_page_entry:
    ; Past last entry?
    mov eax, .current_map_entry
    cmp eax, .memory_map_entries_count
    jnb .memory_entry_unmapped

    ; calculate current address
    mov eax, ecx
    mul dword .page_size

    ; mark real mode memory
    cmp eax, 0x500 ; 1024 real mode IVT + 256 BDA
    jb .page_unavailable

    ; mark kernel memory
    cmp eax, KERNEL_PHY_ADR
    jb .not_kernel_memory
    mov ebx, KERNEL_PHY_ADR
    add ebx, .kernel_size
    cmp eax, ebx
    jnb .not_kernel_memory
    mov al, 1
    jmp .set_entry
.not_kernel_memory:

    ; mark bios service
    cmp eax, 0x1000
    jb .not_bios_service_memory
    cmp eax, buffer + 0x200 ; 512 bytes for read/write buffer
    jnb .not_bios_service_memory
    mov al, 3
    jmp .set_entry
.not_bios_service_memory:

    ; within current entry?
    mov ebx, [esi]
    cmp eax, ebx ; < base?
    jb .memory_entry_unmapped

    add ebx, [esi + 8]
    cmp eax, ebx ; >= base + length
    jnb .try_next_entry

    ; get type from the entry
    mov al, [esi + 16]
    cmp al, 1
    jne .page_unavailable
    mov al, 0
    jmp .set_entry
.page_unavailable:
    mov al, 3
.set_entry:
    mov [edi + 12 + ecx], al
    jmp .post_condition

.try_next_entry:
    add esi, 24 ; go to the next entry
    inc dword .current_map_entry
    jmp .loop_page_entry

.memory_entry_unmapped:
    mov byte [edi + 12 + ecx], 3

.post_condition:
   inc ecx
   cmp ecx, .pages_count
   jb .loop_page_entry

    mov esp, ebp
    pop ebp
    ret 4 * 5
%undef .pages_count
%undef .current_map_entry
%undef .kernel_size
%undef .memory_map_entries_adr
%undef .memory_map_entries_count
%undef .page_size
%undef .memory_size
%undef .layout_data_adr

%include "bios_service/boot_storage.asm"
%include "bios_service/memory_manager.asm"

memory_size: dd 0
memory_map_entries_count: db 0 ; each entry is 24 bits
buffer: