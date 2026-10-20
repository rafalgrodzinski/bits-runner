%define BIOS_SERVICE_REBOOT 0x00
%define BIOS_SERVICE_BOOT_STORAGE_READ_SECTORS 0x02
%define BIOS_SERVICE_BOOT_STORAGE_WRITE_SECTORS 0x04
%define BIOS_SERVICE_BOOT_STORAGE_SECTORS_COUNT 0x03

%define BIOS_SERVICE_INPUT_KEYBOARD_GET_SCAN_CODE_WAITING 0x10
%define BIOS_SERVICE_INPUT_KEYBOARD_GET_KEY 0x11
%define BIOS_SERVICE_INPUT_MOUSE_INIT 0x12
%define BIOS_SERVICE_INPUT_MOUSE_UPDATE 0x13

%define BIOS_SERVICE_VIDEO_VGA_SET_MODE 0x20
%define BIOS_SERVICE_VIDEO_VESA_GET_INFO 0x21
%define BIOS_SERVICE_VIDEO_VESA_GET_MODE_INFO 0x22
%define BIOS_SERVICE_VIDEO_VESA_SET_MODE 0x23
%define BIOS_SERVICE_VIDEO_VESA_SET_DISPLAY_START 0x24
%define BIOS_SERVICE_VIDEO_VESA_GET_FUNCTIONS_TABLE 0x25

%define BIOS_SERVICE_TEXT_MODE_80x25 0x00
%define BIOS_SERVICE_TEXT_MODE_80x50 0x01
%define BIOS_SERVICE_GPXS_MODE_640x480x4 0x12
%define BIOS_SERVICE_GPXS_MODE_320x200x8 0x13

saved_eax: dd 0
mouse_state: times 3 dd 0

;
; BIOS Services
; in
;  ah: service code
[bits 32]
bios_service_32:
    pusha
    cli
    mov [saved_esp], esp
    ; use default real mode stack and put the return address on it
    mov esp, STACK_END_ADR
    sti

    ; Reboot
    cmp eax, BIOS_SERVICE_REBOOT
    jne .not_reboot
    call bios_service_reboot_32
    jmp .end
.not_reboot:

    ; Read sectors
    cmp eax, BIOS_SERVICE_BOOT_STORAGE_READ_SECTORS
    jne .not_read_sectors
    push edx ; target_adr
    push ecx ; sectors_count
    push ebx ; first_sector
    call bios_service_boot_storage_read_sectors_32
    jmp .end
.not_read_sectors:

    ; Write sectors
    cmp eax, BIOS_SERVICE_BOOT_STORAGE_WRITE_SECTORS
    jne .not_write_sectors
    push edx ; source_adr
    push ecx ; sectors_count
    push ebx ; first_sector
    call bios_service_boot_storage_write_sectors_32
    jmp .end
.not_write_sectors:

    ; Sectors count
    cmp eax, BIOS_SERVICE_BOOT_STORAGE_SECTORS_COUNT
    jne .not_sectors_count
    call bios_service_boot_storage_sectors_count_32
    jmp .end
.not_sectors_count:

    ; Input Keyboard Get Scan Code Waiting
    cmp eax, BIOS_SERVICE_INPUT_KEYBOARD_GET_SCAN_CODE_WAITING
    jne .not_input_keyboard_get_scan_code_waiting
    call bios_service_input_keyboard_get_scan_code_waiting_32
    jmp .end
.not_input_keyboard_get_scan_code_waiting:

    ; Input Keyboard Get Key
    cmp eax, BIOS_SERVICE_INPUT_KEYBOARD_GET_KEY
    jne .not_input_keyboard_get_key
    call bios_service_input_keyboard_get_key_32
    jmp .end
.not_input_keyboard_get_key:

    ; Initialize mouse
    cmp eax, BIOS_SERVICE_INPUT_MOUSE_INIT
    jne .not_input_mouse_init
    call bios_service_input_mouse_init_32
    jmp .end
.not_input_mouse_init:

    ; Update mouse
    cmp eax, BIOS_SERVICE_INPUT_MOUSE_UPDATE
    jne .not_input_mouse_update
    call bios_service_input_mouse_update_32
    jmp .end
.not_input_mouse_update:

    ; Video VGA Set Mode
    cmp eax, BIOS_SERVICE_VIDEO_VGA_SET_MODE
    jne .not_video_vga_set_mode
    push ebx ; video_mode
    call bios_service_video_vga_set_mode_32
    jmp .end
.not_video_vga_set_mode:

    ; Video VESA Get Info
    cmp eax, BIOS_SERVICE_VIDEO_VESA_GET_INFO
    jne .not_video_vesa_get_info
    push ebx ; .target_adr
    call bios_service_video_vesa_get_info_32
    jmp .end
.not_video_vesa_get_info:

    ; Video VESA Get Mode Info
    cmp eax, BIOS_SERVICE_VIDEO_VESA_GET_MODE_INFO
    jne .not_video_vesa_get_mode_info
    push ecx ; .mode
    push ebx ; .target_adr
    call bios_service_video_vesa_get_mode_info_32
    jmp .end
.not_video_vesa_get_mode_info:

    ; Video VESA Set Mode
    cmp eax, BIOS_SERVICE_VIDEO_VESA_SET_MODE
    jne .not_video_vesa_set_mode
    push ebx ; .mode
    call bios_service_video_vesa_set_mode_32
    jmp .end
.not_video_vesa_set_mode:

    ; Video VESA Set Display Start
    cmp eax, BIOS_SERVICE_VIDEO_VESA_SET_DISPLAY_START
    jne .not_video_vesa_set_display_start
    push ebx ; .xOffset
    push ecx ; .yOffset
    call bios_service_video_vesa_set_display_start_32
    jmp .end
.not_video_vesa_set_display_start:

    ; Video VESA Get Functions Table
    cmp eax, BIOS_SERVICE_VIDEO_VESA_GET_FUNCTIONS_TABLE
    jne .not_video_vesa_get_functions_table
    call bios_service_video_vesa_get_functions_table_32
    jmp .end
.not_video_vesa_get_functions_table:

.end:
    cli
    ; Restore original kernel stack
    mov esp, [saved_esp]
    sti

    ; Restore original register values, but preserve returned value kept in eax
    mov [saved_eax], eax
    popa
    mov eax, [saved_eax]

    ret

;
; Reboot the system
[bits 32]
bios_service_reboot_32:
    call switch_to_v86_mode_32
[bits 16]
    jmp 0xffff:0

;
; Read sectors from the boot storage
; in
;  first_sector
;  sectors_count
;  target_address
; out
;  eax: read sectors count (0 on error)
%define .args_count 3
%define .first_sector [ebp + 8]
%define .sectors_count [ebp + 12]
%define .target_adr [ebp + 16]
[bits 32]
bios_service_boot_storage_read_sectors_32:
    push ebp
    mov ebp, esp

    push dword buffer ; buffer_adr
    push dword .target_adr ; target_adr
    push dword .sectors_count ; sectors_count
    push dword .first_sector ; first_sector
    call boot_storage_read_sectors_32

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .target_address
%undef .sectors_count
%undef .source_lba_address
%undef .args_count

;
; Write sectors to the boot storage
; in
;  first_sector
;  sectors_count
;  source_address
; out
;  eax: written sectors count (0 on error)
%define .args_count 3
%define .first_sector [ebp + 8]
%define .sectors_count [ebp + 12]
%define .source_adr [ebp + 16]
[bits 32]
bios_service_boot_storage_write_sectors_32:
    push ebp
    mov ebp, esp

    push dword buffer ; buffer_adr
    push dword .source_adr ; target_adr
    push dword .sectors_count ; sectors_count
    push dword .first_sector ; first_sector
    call boot_storage_write_sectors_32

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .source_address
%undef .sectors_count
%undef .source_lba_address
%undef .args_count

;
; Wait for keyboard input
; out
;  eax: scan code
[bits 32]
bios_service_input_keyboard_get_scan_code_waiting_32:
    call switch_to_v86_mode_32
[bits 16]
    mov ah, 0x00
    int 0x16
    mov al, ah ; ah: scan code, al: ascii
    mov ah, 0x00

    call switch_to_protected_mode_16
[bits 32]
    ret

;
; Get current keyboard input without waiting
; out
;  ah: scan code
;  al: ascii
[bits 32]
bios_service_input_keyboard_get_key_32:
    call switch_to_v86_mode_32
[bits 16]
    mov cx, 1000
.loop:
    mov ah, 0x01
    int 0x16
    jz .no_key

    mov ah, 0x00
    int 0x16
    movzx eax, ax
    jmp .end

.no_key:
    xor eax, eax
    loop .loop
.end:
    call switch_to_protected_mode_16
[bits 32]
    ret

;
; Initialize mouse callback and return address with status
; out
;  eax: status address
[bits 32]
bios_service_input_mouse_init_32:
    call switch_to_v86_mode_32
[bits 16]
    ; Initialize
    mov ax, 0xc205
    mov bh, 3
    int 0x15
    jc .init_failed

    ; Set callback
    mov ax, 0xc207
    mov bx, bios_service_mouse_callback_16
    int 0x15
    jc .init_failed

    ; Enable
    mov ax, 0xc200
    mov bh, 0x01
    int 0x15
    jc .init_failed

    mov eax, mouse_state
    jmp .end

.init_failed:
    mov eax, 0x00
.end:
    call switch_to_protected_mode_16
[bits 32]
    ret

;
; Run a bit in real mode so the mouse interrupt has a moment to arrive
[bits 32]
bios_service_input_mouse_update_32:
    call switch_to_v86_mode_32
[bits 16]

.flushed:
    mov cx, 10000
.wait:
    in al, 0x80
    loop .wait

    call switch_to_protected_mode_16
[bits 32]
    ret

;
; Callback for BIOS mouse interrupt
%define .status [bp + 12]
%define .delta_x [bp + 10]
%define .delta_y [bp + 8]
[bits 16]
bios_service_mouse_callback_16:
    push bp
    mov bp, sp
    push eax

    movzx eax, word .status
    and eax, 0111b
    mov [cs:mouse_state], eax

    movzx eax, word .delta_x
    test .status, 00010000b
    jz .x_not_negative
    or eax, 0xffff_ff00
.x_not_negative:
    add [cs:mouse_state + 4], eax

    movzx eax, word .delta_y
    test .status, 00100000b
    jz .y_not_negative
    or eax, 0xffff_ff00
.y_not_negative:
    add [cs:mouse_state + 8], eax

    pop eax
    pop bp
    retf
%undef .delta_y
%undef .delta_x
%undef .status

;
; Get number of sectors of the boot storage
;  out
;   eax: sectors_count
[bits 32]
bios_service_boot_storage_sectors_count_32:
    ; eax <- cylinders * heads * sectors
    mov eax, [boot_storage_drive_cylinders]
    mul dword [boot_storage_drive_heads]
    mul dword [boot_storage_drive_sectors]

    ret

;
; Video VGA Set Mode
; in
;  video_mode
%define .args_count 1
%define .video_mode [ebp + 8]
[bits 32]
bios_service_video_vga_set_mode_32:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode_32
[bits 16]
    ; text 80x25
    cmp dword .video_mode, BIOS_SERVICE_TEXT_MODE_80x25
    jne .not_80x25
    mov ax, 0x0003
    mov bl, 0
    int 0x10
    jmp .end
.not_80x25:

    ; text 80x50
    cmp dword .video_mode, BIOS_SERVICE_TEXT_MODE_80x50
    jne .not_80x50
    mov ax, 0x1112
    mov bl, 0
    int 0x10
    jmp .end
.not_80x50:

    ;graphics 320x200x8
    cmp dword .video_mode, BIOS_SERVICE_GPXS_MODE_320x200x8
    jne .not_320x200x8
    mov ax, 0x0013
    int 0x10
    jmp .end
.not_320x200x8:

    ;graphics 640x480x4
    cmp dword .video_mode, BIOS_SERVICE_GPXS_MODE_640x480x4
    jne .not_640x480x4
    mov ax, 0x0012
    int 0x10
    jmp .end
.not_640x480x4:

.end:
    call switch_to_protected_mode_16
[bits 32]

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .video_mode
%undef .args_count

;
; VESA Get Info
; in
;  .target_adr
%define .args_count 1
%define .target_adr [ebp + 8]
[bits 32]
bios_service_video_vesa_get_info_32:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode_32
[bits 16]
    mov ax, 0x4f00
    mov di, buffer
    int 0x10

    call switch_to_protected_mode_16
[bits 32]
    ; Copy retreived data to the target address
    mov ecx, 0x200
    mov esi, buffer
    mov edi, .target_adr
    rep movsb

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .target_adr
%undef .args_count

;
; VESA Get Mode Info
; in
;  .target_adr
;  .mode
%define .args_count 2
%define .target_adr [ebp + 8]
%define .mode [ebp + 12]
[bits 32]
bios_service_video_vesa_get_mode_info_32:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode_32
[bits 16]
    mov ax, 0x4f01
    mov di, buffer
    mov cx, .mode
    int 0x10

    call switch_to_protected_mode_16
[bits 32]
    ; Copy retreived data to the target address
    mov ecx, 0x100
    mov esi, buffer
    mov edi, .target_adr
    rep movsb

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .mode
%undef .target_adr
%undef .args_count

;
; VESA Set Mode
; in
;  .mode
%define .args_count 1
%define .mode [ebp + 8]
[bits 32]
bios_service_video_vesa_set_mode_32:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode_32
[bits 16]
    mov ax, 0x4f02
    mov bx, .mode
    and bx, 0x3fff ; Clear two top bits
    or bx, 0x4000 ; Set bit 14 to enable linear frame buffer
    int 0x10

    call switch_to_protected_mode_16
[bits 32]

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .mode
%undef .args_count

;
; VESA Set Display Start
; in
;  .xOffset
;  .yOffset
%define .args_count 2
%define .xOffset [ebp + 8]
%define .yOffset [ebp + 12]
[bits 32]
bios_service_video_vesa_set_display_start_32:
    push ebp
    mov ebp, esp

    call switch_to_v86_mode_32
[bits 16]
    mov ax, 0x4f07
    mov bx, 0x0000
    mov ecx, .xOffset
    mov edx, .yOffset
    int 0x10

    call switch_to_protected_mode_16
[bits 32]

    mov esp, ebp
    pop ebp
    ret U32_SIZE * .args_count
%undef .yOffset
%undef .xOffset
%undef .args_count

;
; VESA Get functions table
; out
;  eax: functions table pointer
[bits 32]
bios_service_video_vesa_get_functions_table_32:
    call switch_to_v86_mode_32
[bits 16]
    mov ax, 0x4f0a
    mov bl, 0x00
    int 0x10

    cmp ax, 0x004f
    je .supported
    mov eax, 0x00
    jmp .end

.supported:
    mov ax, es
    movzx eax, ax
    shl eax, 4
    movzx edi, di
    add eax, edi

.end:
    call switch_to_protected_mode_16
[bits 32]

    ret