org 0x7c00
cpu 8086
bits 16

main:
	jmp short start
	nop

; FAT12 header
; BPB (BIOS Parameter Block)
db "MSDOS5.0" ; (8 bytes)
bpb_bytes_per_sector: dw 512
db 1 ; sectors per cluster
bpb_reserved_sectors_count: dw 1
bpb_fats_count: db 2
bpb_root_dir_entries_count: dw 512
dw 2880 ; sectors count
db 0xf0 ; media descriptor
bpb_sectors_per_fat: dw 9
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

;%define fat1 512 ; 512 * 9
;%define buffer 0x7c00 + 512 ; 512
%define name_buffer 0x7c00 + 512 + 512 ; 16

start:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax

	;mov sp, 0x7c00

	; Show welcome message
	mov ax, msg_welcome
	call print
	call print_new_line
	
	; Get number of sectors to read
	mov ax, [bpb_root_dir_entries_count]
	mov cl, 5
	shl ax, cl ; ax *= 32
	div word [bpb_bytes_per_sector]
	mov cx, ax
	
	; Get starting sector
	mov ax, [bpb_sectors_per_fat]
	mul byte [bpb_fats_count]
	add ax, [bpb_reserved_sectors_count]

	; Read root directory
	mov bx, buffer
	call read_floppy_data

	mov ax, buffer
	mov bx, kernel_file_name
	call find_cluster_number

	call print_int
	call print_new_line

	; Should not reach this
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
	push ax

	mov ah, 0x0e
	mov al, " "
	int 0x10

	pop ax
	ret
	
; Print new line
print_new_line:
	push ax

	mov ah, 0x0e
	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10
	
	pop ax
	ret

; Print string
; in
;  ax: message address
print:	
	push ax
	push bx
	push si

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

	pop si
	pop bx
	pop ax
	ret

; Print integer
; ax - integer to print
print_int:
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, 0
process_digit:
	inc cx
	mov dx, 0
	mov si, 10
	idiv si
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
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Print contents of memory
; ax: address
; bx: count
dump_bytes:
	push ax
	push bx
	push si
	
	mov si, ax
	add bx, ax
	mov ax, 0
.loop:
	lodsb
	call print_int
	call print_space
	cmp si, bx
	jne .loop
	
	pop si
	pop bx
	pop ax
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
%define floppy_cylinders_count 80
%define floppy_sectors_count 18
%define floppy_heads_count 2
	push ax
	push cx
	push dx
	push di
	
	call lba_to_chs

	mov dl, 0 ; drive number

	; try reading 3 times
	mov di, 3
.loop:
	mov al, cl ; sectors to read
	mov ah, 0x02
	int 0x13
	jnc .read_successful
	dec di
	cmp di, 0
	jnz .loop

	; Read failed
	mov ax, msg_disk_read_failed
	call fatal_error
.read_successful:
	
	pop di
	pop dx
	pop cx
	pop ax
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
	add di, 32
	inc ax
	cmp ax, [bpb_root_dir_entries_count]
	jl .loop
	
	; Gone through all file entries, nothing found
	mov ax, 0
	jmp .not_found

.found_file:
	mov ax, [di + 26]

.not_found:
	pop si
	pop di
	pop bx
	ret

kernel_file_name db "BOOT    ASM", 0
msg_welcome db "Welcome to Dummy OS!", 0
msg_bootstrap_failed db "Fatal Error! Bootstrap failed.", 0
msg_disk_read_failed db "Fatal Error! Failed to read disk.", 0
times 510 - ($ - $$) db 0
db 0x55, 0xaa

buffer:
