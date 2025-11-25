[org 0x7c00]
[cpu 386]
[bits 16]

jmp short start
nop

%define FAT_BYTES_PER_ENTRY 32
%define FAT_ENTRY_CLUSTER_OFFSET 26
%define FAT_EOF 0x0ff8

%define ADDRESS_BIOS_SERVICE 0x1000 ; 4KiB

; FAT12 header (filled-in by formatting utility)
; BPB (BIOS Parameter Block)
times 8 db 0; label
bpb_bytes_per_sector: dw 0
db 0 ; sectors per cluster
bpb_reserved_sectors_count: dw 0
bpb_fats_count: db 0
bpb_root_dir_entries_count: dw 0
dw 0 ; sectors count
db 0 ; media descriptor
bpb_sectors_per_fat: dw 0
bpb_sectors_per_track: dw 0
bpb_heads_count: dw 0
bpb_hidden_sectors: dd 0
dd 0 ; large sectors
; Extended Boot Record
db 0 ; drive number
db 0 ; unused
db 0 ; boot signature
dd 0 ; serial number
times 11 db 0 ; volume label (11 bytes)
times 8 db 0 ; file system type (8 bytes)

start:
	; Setup segments
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00

	; store boot drive number
	mov [boot_drive_number], dl

	; Set video mode to 80x25
    mov ax, 0x0003
    int 0x10
	
	; Show loading message
	mov si, msg_loading
	call print_string

	; Read drive CHS geometry
	mov ah, 0x08
	int 0x13
	and cl, 0x3f ; only bits 5-0 are used (7-6 are used fore cylinders)
	mov [bpb_sectors_per_track], cl
	inc dh
	mov [bpb_heads_count], dh

	; fat_root_dir_offset
	mov ax, [bpb_sectors_per_fat]
	mul word [bpb_fats_count]
	add ax, [bpb_reserved_sectors_count]
	add ax, [bpb_hidden_sectors]
	mov [fat_root_dir_offset], ax

	; fat_root_dir_sectors_count
	mov dx, 0
	mov ax, [bpb_root_dir_entries_count]
	mov bx, FAT_BYTES_PER_ENTRY
	mul bx
	div word [bpb_bytes_per_sector]
	mov [fat_root_dir_sectors_count], ax

	; fat first data sector
	mov ax, [fat_root_dir_offset]
	add ax, word [fat_root_dir_sectors_count]
	sub ax, 2
	mov [fat_first_data_sector], ax

	; Read root directory
	mov ax, [fat_root_dir_offset]
	mov bx, buffer
	mov cx, [fat_root_dir_sectors_count]
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
	mov ax, [bpb_reserved_sectors_count]
	mov bx, buffer
	mov cx, [bpb_sectors_per_fat]
	call read_sectors
	
	; Load file
	pop ax ; restore cluster number
	mov bx, buffer ; fat buffer
	mov cx, ADDRESS_BIOS_SERVICE
	call load_file

	; File loaded, start execution
	mov dl, [boot_drive_number] ; also pass boot disk number
	mov ax, [bpb_hidden_sectors] ; and starting sector
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
read_sectors:
	pusha
	
	mov di, cx ; preserve sectors count (cx overriten by lba_to_chs)
	call lba_to_chs

	mov ax, 0
	mov es, ax ; target address is pair es:bx
	mov dl, [boot_drive_number]
	mov ax, di ; restore sectors count

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
	cmp ax, [bpb_root_dir_entries_count]
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

	add ax, [fat_first_data_sector]
	mov bx, cx
	mov cx, 1
	call read_sectors
	popa
	add cx, [bpb_bytes_per_sector]

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

boot_drive_number: db 0
fat_first_data_sector dw 0
fat_root_dir_offset dw 0
fat_root_dir_sectors_count dw 0

times 510 - ($ - $$) db 0 ; padding
db 0x55, 0xaa ; magic number

buffer: