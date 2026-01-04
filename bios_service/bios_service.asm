%define BIOS_SERVICE_REBOOT 0x00
%define BIOS_SERVICE_SET_VIDEO_MODE 0x01
%define BIOS_SERVICE_BOOT_STORAGE_READ_SECTORS 0x02
%define BIOS_SERVICE_BOOT_STORAGE_SECTORS_COUNT 0x03

%define BIOS_SERVICE_TEXT_MODE_80x25 0x00
%define BIOS_SERVICE_TEXT_MODE_80x50 0x01
%define BIOS_SERVICE_GPXS_MODE_320x200x8 0x02
%define BIOS_SERVICE_GPXS_MODE_640x480x4 0x03

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
    cmp ah, BIOS_SERVICE_REBOOT
    jne .not_reboot
    call bios_service_reboot_32
    jmp .end
.not_reboot:

    ; Video mode
    cmp ah, BIOS_SERVICE_SET_VIDEO_MODE
    jne .not_set_video_mode
    call bios_service_set_video_mode_32
    jmp .end
.not_set_video_mode:

    ; Read sectors
    cmp ah, BIOS_SERVICE_BOOT_STORAGE_READ_SECTORS
    jne .not_read_sectors
    push edi ; target_adr
    push ecx ; sectors_count
    push ebx ; first_sector
    call bios_service_boot_storage_read_sectors_32
    jmp .end
.not_read_sectors:

    ; Sectors count
    cmp ah, BIOS_SERVICE_BOOT_STORAGE_SECTORS_COUNT
    jne .not_sectors_count
    call bios_service_boot_storage_sectors_count_32
    jmp .end
.not_sectors_count:

.end:
    cli

    mov esp, [saved_esp]

    sti

    popa
    ret

;
; Reboot the system
[bits 32]
bios_service_reboot_32:
    call switch_to_v86_mode_32
[bits 16]
    jmp 0xffff:0

;
; Change video mode
; in
;  al: video mode
[bits 32]
bios_service_set_video_mode_32:
    call switch_to_v86_mode_32

[bits 16]
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
    call switch_to_protected_mode_16
[bits 32]
    ret

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
    ret 4 * .args_count
%undef .target_address
%undef .sectors_count
%undef .source_lba_address
%undef .args_count

;
; Get number of sectors of the boot storage
;  out
;   sectors_count
[bits 32]
bios_service_boot_storage_sectors_count_32:
    ; eax <- cylinders * heads * sectors
    mov eax, [boot_storage_drive_cylinders]
    mul dword [boot_storage_drive_heads]
    mul dword [boot_storage_drive_sectors]
bits 32
    ret