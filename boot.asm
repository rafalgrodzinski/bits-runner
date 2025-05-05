org 0x7c00
cpu 386
bits 16

main:
	jmp short start
	nop

; FAT12 header
%define bpb_bytes_per_sector 512
%define bpb_reserved_sectors_count 1
%define bpb_fats_count 2
%define bpb_root_dir_entries_count 512
%define bpb_sectors_per_fat 9

%define FAT_BYTES_PER_ENTRY 32
%define FAT_ENTRY_CLUSTER_OFFSET 26
%define FAT_FIRST_DATA_SECTOR bpb_reserved_sectors_count + (bpb_fats_count * bpb_sectors_per_fat) + ((bpb_root_dir_entries_count * FAT_BYTES_PER_ENTRY) / bpb_bytes_per_sector) - 2
%define FAT_ROOT_DIR_OFFSET bpb_reserved_sectors_count + bpb_sectors_per_fat * bpb_fats_count
%define FAT_ROOT_DIR_SECTORS_COUNT (bpb_root_dir_entries_count * FAT_BYTES_PER_ENTRY) / bpb_bytes_per_sector

%define FAT_EOF 0x0ff8

%define BUFFER_KERNEL buffer + bpb_sectors_per_fat * bpb_bytes_per_sector

; BPB (BIOS Parameter Block)
db "MSDOS5.0" ; (8 bytes)
dw bpb_bytes_per_sector
db 1 ; sectors per cluster
dw bpb_reserved_sectors_count
db bpb_fats_count
dw bpb_root_dir_entries_count
dw 2880 ; sectors count
db 0xf0 ; media descriptor
dw bpb_sectors_per_fat
floppy_sectors_per_track: dw 18
floppy_heads_count: dw 2
dd 0 ; hidden sectors
dd 0 ; large sectors
; Extended Boot Record
db 0 ; drive number
db 0 ; unused
db 0x29 ; boot signature
dd 0 ; serial number
db "NO NAME    " ; volume label (11 bytes)
db "FAT12   " ; file system type (8 bytes)

start:
	; Setup
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00

	; Show welcome message
	mov ax, msg_welcome
	call print
	call print_new_line

	; Read root directory
	mov ax, FAT_ROOT_DIR_OFFSET
	mov bx, buffer
	mov cx, FAT_ROOT_DIR_SECTORS_COUNT
	call read_floppy_data

	; Find fat cluster number for kernel file
	mov ax, buffer
	mov bx, kernel_file_name
	call find_cluster_number
	cmp ax, 0
	jnz .kernel_found

	; Kernel not found
	mov ax, msg_kernel_file_not_found
	call fatal_error
	
.kernel_found:
	push ax ; preserve found cluster number

	; Read first fat entry
	mov ax, bpb_reserved_sectors_count
	mov bx, buffer
	mov cx, bpb_sectors_per_fat
	call read_floppy_data
	
	; Load kernel file
	pop ax ; restore cluster number
	mov bx, buffer ; fat buffer
	mov cx, BUFFER_KERNEL ; Right after loaded fat 1 table
	call load_file

	; Should not reach this point
	mov ax, msg_bootstrap_failed
	call fatal_error

; Stop execution and show message
; in
;  ax: message address
fatal_error:
	call print
	hlt
.halt:
	jmp .halt
	
; Print space
print_space:
	pusha

	mov ah, 0x0e
	mov al, " "
	int 0x10

	popa
	ret
	
; Print new line
print_new_line:
	pusha

	mov ah, 0x0e
	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10
	
	popa
	ret

; Print string
; in
;  ax: message address
print:	
	pusha

	mov si, ax
	mov bx, 0
	mov ah, 0x0e

.loop:
	lodsb
	cmp al, 0
	jz .string_finished ; if al == 0
	int 0x10
	jmp .loop

.string_finished:
	popa
	ret

; Print integer
; in
;  ax; integer to print
print_int:
	pusha

	mov cx, 0

process_digit:
	inc cx
	mov dx, 0
	mov si, 10
	div si
	add dx, "0"
	push dx
	cmp ax, 0
	jnz process_digit

print_digit:
	dec cx
	mov ax, sp
	call print
	pop ax
	cmp cx, 0
	jnz print_digit

	popa
	ret

; Print contents of memory
; in
;  ax: address
;  bx: count
dump_bytes:
	pusha
	
	mov si, ax
	add bx, ax
	mov ax, 0
.loop:
	lodsb
	call print_int
	call print_space
	cmp si, bx
	jne .loop
	
	popa
	ret
	
; Converts LBA to CHS addressing
; in
;  ax: LBA address
; out
;  cl: sector
;  dh: head
;  ch: cylinder
lba_to_chs:
	push ax
	
	div byte [floppy_sectors_per_track]
	mov cl, ah
	add cl, 1 ; sector, lba % sectors per track + 1
	
	mov ah, 0
	div byte [floppy_heads_count]
	mov dh, ah ; head, (lba / secttors per track) % heads
	mov ch, al ; cylinder, (lba / secttors per track) / heads
	
	pop ax
	ret

; Read sectors from floppy
; in
;  ax: LBA addressed sector to read
;  bx: buffer address
;  cx: number of sectors to read
read_floppy_data:
	pusha
	
	push cx ; preserve source address
	call lba_to_chs
	mov dl, 0 ; drive number
	pop ax ; restore source address

	; try reading 3 times
	mov di, 3
.loop:
	mov ah, 0x02
	
	int 0x13
	jnc .read_successful
	dec di
	jnz .loop

	; Read failed
	mov ax, msg_disk_read_failed
	call fatal_error

.read_successful:
	popa
	ret

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
	cmp ax, bpb_root_dir_entries_count
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
	call read_floppy_data
	popa
	add cx, bpb_bytes_per_sector

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

kernel_file_name db "BOOT    ASM", 0
;kernel_file_name db "KERNEL  BIN", 0
msg_welcome db "Booting Dummy OS...", 0
msg_bootstrap_failed db "Boot failed!", 0
msg_disk_read_failed db "Failed to read disk!", 0
msg_kernel_file_not_found db "KERNEL.BIN not found!"
times 510 - ($ - $$) db 0
db 0x55, 0xaa

buffer:
