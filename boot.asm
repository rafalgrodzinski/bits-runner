org 0x7c00
cpu 8086
bits 16

	jmp short start
	nop
	
; FAT12 header
db "MSDOS5.0" ; (8 bytes)
dw 512 ; bytes per sector
db 1 ; sectors per cluster
dw 1 ; reserved sectors count
db 2 ; FATs count
dw 512 ; root directory entries count
dw 2880 ; sectors count
db 0xf0 ; media descriptor
dw 9 ; sectors per FAT
dw 18  ; sectors per track 0x20
dw 2 ; heads per cylinder 0x10
dd 0 ; hidden sectors
dd 0 ; large sectors
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

	mov sp, 0x7c00

	mov ax, message_welcome
	call print
	
	mov ax, lf
	call print
	
	;mov ax, 1
	;mov bx, fat1
	;mov cx, 9
	;call read_floppy_data
	
	mov ax, 19
	mov bx, buffer
	mov cx, 1
	call read_floppy_data
	
	mov ax, buffer
	call print
	
	mov ax, buffer
	call read_file
	
	call stop

; Print string
; ax - pointer to message
print:	
	push ax
	push bx
	push cx
	push dx
	push si

	mov si, ax
	
	mov ah, 0x0e
	mov bl, 0
	mov bh, 0
.next_char:
	lodsb
	cmp al, 0
	jz .string_finished ; if al == 0
	int 10h
	jmp .next_char
.string_finished:

	pop si
	pop dx
	pop cx
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

; Read floppy
; ax: linear sector to read
; bx: buffer address
; cx: sectors to read
read_floppy_data:
%define floppy_cylinders_count 80
%define floppy_sectors_count 18
%define floppy_heads_count 2
	push ax
	push bx
	push cx
	push dx
	push si
	
	push cx
	
	mov dx, floppy_sectors_count
	div dl
	mov cl, ah ; sector, lba % sectors per track + 1
	add cl, 1

	mov ah, 0
	mov dx, floppy_heads_count
	div dl
	mov dh, ah ; head, (lba / secttors per track) % heads
	mov ch, al ; cylinder, (lba / secttors per track) / heads
	mov dl, 0 ; drive
	
	pop ax ; sectors to read
	mov ah, 0x02
	int 0x13
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Stop execution
stop:
	hlt
.halt:
	jmp .halt
	
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
	
	mov ax, lf
	call print
	
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

	message_welcome db "Welcome to Dummy OS!", 0
	lf db ` `, 0
	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
	
; dynamic data
;fat1: resb 512 * 9
;buffer: resb 512
;name_buffer: resb 16


