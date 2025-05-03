org 0x7c00
cpu 8086
bits 16

	jmp short start
	nop

; FAT12 header
; BPB (BIOS Parameter Block)
db "MSDOS5.0" ; (8 bytes)
dw 512 ; bytes per sector
db 1 ; sectors per cluster
bpb_reserved_sectors_count: dw 1
bpb_fats_count: db 2
dw 512 ; root directory entries count
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
%define buffer 0x7c00 + 512 ; 512
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
	
	mov ax, [bpb_sectors_per_fat]
	mul [bpb_fats_count]

	;mov ax, 1
	;mov bx, fat1
	;mov cx, 9
	;call read_floppy_data

	mov ax, 19
	mov bx, buffer
	mov cx, 1
	call read_floppy_data
	
	;mov ax, buffer
	;call print
	
	;mov ax, buffer
	;call read_file
	
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
	
; Print new line
print_new_line:
	mov ah, 0x0e
	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10

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
	
; ax: address
; bx: count
dump_bytes:
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, 0
.loop:
	mov si, ax
	add si, cx
	mov dh, 0
	mov dl, [si]
	push ax
	mov ax, dx
	call print_int

	pop ax
	inc cx
	cmp cx, bx
	jl .loop
	
	pop si
	pop dx
	pop cx
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

; Read file
read_file:
	push ax
	push bx
	push cx
	push dx
	push si
filename:
	mov cx, 0
	mov bx, ax
	add bx, cx
	mov dl, [bx]
	mov bx, name_buffer
	add bx, cx
	mov [bx], dl
	inc cx
	cmp cx, 8
	jl filename
	
	mov bx, name_buffer
	add bx, 8
	mov byte [bx], "."
	
extension:
	mov cx, 0
	mov bx, ax
	add bx, 8
	add bx, cx
	mov dl, [bx]
	mov bx, name_buffer
	add bx, 9
	add bx, cx
	mov [bx], dl
	inc cx
	cmp cx, 3
	jl extension
	
	mov byte [name_buffer + 13], 0
	
	mov ax, name_buffer
	call print
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

msg_welcome db "Welcome to Dummy OS!", 0
msg_bootstrap_failed db "Fatal Error! Bootstrap failed.", 0
msg_disk_read_failed db "Fatal Error! Failed to read disk.", 0
times 510 - ($ - $$) db 0
db 0x55, 0xaa
	
; dynamic data
;fat1: resb 512 * 9
;buffer: resb 512
;name_buffer: resb 16


