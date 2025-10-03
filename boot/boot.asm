org 0x7c00

cpu 386
bits 16

jmp short start
nop

%define BPB_BYTES_PER_SECTOR 512
%define BPB_RESERVED_SECTORS_COUNT 1
%define BPB_FATS_COUNT 2
%define BPB_ROOT_DIR_ENTRIES_COUNT 512
%define BPB_SECTORS_PER_FAT 9
%define BPB_SECTORS_PER_TRACK 18
%define BPB_HEADS_COUNT 2

%define FAT_BYTES_PER_ENTRY 32
%define FAT_ENTRY_CLUSTER_OFFSET 26
%define FAT_FIRST_DATA_SECTOR BPB_RESERVED_SECTORS_COUNT + (BPB_FATS_COUNT * BPB_SECTORS_PER_FAT) + ((BPB_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / BPB_BYTES_PER_SECTOR) - 2
%define FAT_ROOT_DIR_OFFSET BPB_RESERVED_SECTORS_COUNT + BPB_SECTORS_PER_FAT * BPB_FATS_COUNT
%define FAT_ROOT_DIR_SECTORS_COUNT (BPB_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / BPB_BYTES_PER_SECTOR

%define FAT_EOF 0x0ff8

%define BOOT_SECTOR_ID_OFFSET 0x7dfe
%define ADDRESS_BIOS_SERVICE 0x1000 ; 4KiB

; FAT12 header
; BPB (BIOS Parameter Block)
db "MSDOS5.0" ; label (8 bytes)
dw BPB_BYTES_PER_SECTOR
db 1 ; sectors per cluster
dw BPB_RESERVED_SECTORS_COUNT
db BPB_FATS_COUNT
dw BPB_ROOT_DIR_ENTRIES_COUNT
dw 2880 ; sectors count
db 0xf0 ; media descriptor
dw BPB_SECTORS_PER_FAT
bpb_sectors_per_track: dw BPB_SECTORS_PER_TRACK
bpb_heads_count: dw BPB_HEADS_COUNT
dd 0 ; hidden sectors
dd 0 ; large sectors
; Extended Boot Record
db 0 ; drive number
db 0 ; unused
db 0x29 ; boot signature
dd 0 ; serial number
db "BITS RUNNER" ; volume label (11 bytes)
db "FAT12   " ; file system type (8 bytes)

boot_drive_number: db 0

start:
	; Setup segments
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00

	; store boot drive number
	mov [boot_drive_number], dl
	
	; Show loading message
	mov si, msg_loading
	call print_string

	; Read drive CHS geometry if HDD
	cmp dl, 0x80 ; first hard disk number
	jb .skip_chs_detection
	mov ah, 0x08
	int 0x13
	mov [bpb_sectors_per_track], cl
	mov [bpb_heads_count], dh
	inc byte [bpb_heads_count]
.skip_chs_detection:

	; Read root directory
	mov ax, FAT_ROOT_DIR_OFFSET
	mov bx, buffer
	mov cx, FAT_ROOT_DIR_SECTORS_COUNT
	mov dl, [boot_drive_number]
	call read_sectors

	; Find fat cluster number for bios service file
	mov ax, buffer
	mov bx, bios_service_file_name
	call find_cluster_number
	cmp ax, 0
	jnz .file_found

	; File not found
	mov si, msg_bios_service_file_not_found
	call fatal_error
	
.file_found:
	push ax ; preserve found cluster number

	; Read first fat entry
	mov ax, BPB_RESERVED_SECTORS_COUNT
	mov bx, buffer
	mov cx, BPB_SECTORS_PER_FAT
	mov dl, [boot_drive_number]
	call read_sectors
	
	; Load file
	pop ax ; restore cluster number
	mov bx, buffer ; fat buffer
	mov cx, ADDRESS_BIOS_SERVICE
	call load_file

	; File loaded, start execution
	mov dl, [boot_drive_number] ; also pass boot disk number
	jmp (ADDRESS_BIOS_SERVICE >> 4):0

;
; Stop execution and show message
; in
;  si: message address
fatal_error:
	call print_string
	hlt
.halt:
	jmp .halt

;
; Print string
; in
;  si: message address
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
	; print new line
	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10

	popa
	ret

;
; Converts LBA to CHS addressing
; in
;  ax: LBA address
; out
;  cl: sector
;  dh: head
;  ch: cylinder
lba_to_chs:
	push ax
	
	div byte [bpb_sectors_per_track]
	mov cl, ah
	add cl, 1 ; sector, lba % sectors per track + 1
	
	mov ah, 0
	div byte [bpb_heads_count]
	mov dh, ah ; head, (lba / secttors per track) % heads
	mov ch, al ; cylinder, (lba / secttors per track) / heads
	
	pop ax
	ret

;
; Read sectors from a device
; in
;  ax: LBA address of the first sector
;  bx: buffer address
;  cx: number of sectors to read
;  dl: drive number
read_sectors:
	pusha
	
	push cx ; preserve sectors count (cx overriten by lba_to_chs)
	call lba_to_chs
	pop ax ; restore sectors count

	; try reading 3 times
	mov di, 3
.loop:
	mov ah, 0x02
	
	int 0x13
	jnc .read_successful
	dec di
	jnz .loop

	; Read failed
	mov si, msg_disk_read_failed
	call fatal_error

.read_successful:
	popa
	ret

;
; Try finding cluster number for a file of a given name
; in
;  ax: root dir buffer address
;  bx: file name address
; out
;  ax: cluster number (or 0 if not found)
find_cluster_number:
	push bx
	push di
	push si
	
	mov di, ax ; current entry address
	mov ax, 0 ; current entry count

.loop:
	mov si, bx ; searching file name
	mov cx, 11 ; chars in file name
	push di
	repe cmpsb ; Try matching file names
	pop di
	je .found_file
	
	; Try next entry
	add di, FAT_BYTES_PER_ENTRY
	inc ax
	cmp ax, BPB_ROOT_DIR_ENTRIES_COUNT
	jl .loop
	
	; Gone through all file entries, nothing found
	mov ax, 0
	jmp .not_found

.found_file:
	mov ax, [di + FAT_ENTRY_CLUSTER_OFFSET]

.not_found:
	pop si
	pop di
	pop bx
	ret

;
; Load file into memory starting with given cluster number
; in
;  ax: fat cluster number
;  bx: fat buffer address
;  cx: target address
load_file:
	pusha
	
.loop:
	; Load sector pointed by cluster into memory
	pusha
	add ax, FAT_FIRST_DATA_SECTOR
	mov bx, cx
	mov cx, 1
	mov dl, [boot_drive_number]
	call read_sectors
	popa
	add cx, BPB_BYTES_PER_SECTOR

	; Load next next fat cluster
	mov si, 3
	mul si
	mov si, 2
	div si ; Divide by 1.5 since we're extracting 12 bits (1.5 byte)
	
	mov si, bx
	add si, ax
	mov ax, [si]

	; Adjust 12 bit to 16 bit
	or dx, dx
	jz .even
.odd:
	shr ax, 4
	jmp .next_cluster
.even:
	and ax, 0x0fff

.next_cluster:		
	cmp ax, FAT_EOF ; range 0x0ff8 - 0x0fff marks last fat cluster
	jb .loop

	popa
	ret

; Messages
bios_service_file_name: db `BIOS_SVCBIN\0`
msg_loading: db `Loading BIOS Service...\0`

msg_disk_read_failed: db `Failed to read disk!\0`
msg_bios_service_file_not_found: db `BIOS_SVC.BIN not found!\0`

times 510 - ($ - $$) db 0 ; padding
db 0x55, 0xaa ; magic number

buffer: