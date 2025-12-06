%define BIOS_SERVICE_REBOOT 0x00
%define BIOS_SERVICE_SET_VIDEO_MODE 0x01
%define BIOS_SERVICE_READ_SECTORS 0x02
%define BIOS_SERVICE_SECTORS_COUNT 0x03

%define BIOS_SERVICE_TEXT_MODE_80x25 0x00
%define BIOS_SERVICE_TEXT_MODE_80x50 0x01
%define BIOS_SERVICE_GPXS_MODE_320x200x8 0x02
%define BIOS_SERVICE_GPXS_MODE_640x480x4 0x03

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
    call switch_to_v86_mode_32
bits 16
    jmp 0xffff:0

;
; Change video mode
; in
;  al: video mode
bits 32
set_video_mode:
    call switch_to_v86_mode_32

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
    call switch_to_protected_mode_16
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
    ;call read_sectors

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

    call switch_to_v86_mode_32
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

    call switch_to_protected_mode_16
bits 32

    mov esp, ebp
    pop ebp
    ret 4 * 1