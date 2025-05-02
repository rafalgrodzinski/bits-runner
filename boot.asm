org 0x7c00
bits 16

	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax

	mov sp, 0x7c00

	mov ax, message_welcome
	call print
	
	mov ax, 2
	mov bx, buffer
	mov cx, 1
	call read_floppy_data

	mov ax, buffer
	call print
	
	call stop

; Print string
; ax - pointer to message
print:	
	pusha
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

	popa
	ret

; Print integer
; ax - integer to print
print_int:
	pusha
	
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
	
	popa
	ret

; Read floppy
; ax: linear sector to read
; bx: buffer address
; cx: sectors to read
read_floppy_data:
%define floppy_cylinders_count 80
%define floppy_sectors_count 18
%define floppy_heads_count 2
	pusha
	push cx
	
	mov dx, floppy_sectors_count
	div dl
	mov cl, ah ; sector, lba / sectors per track + 1
	add cl, 1

	mov ah, 0
	mov dx, floppy_heads_count
	div dl
	mov ch, ah ; cylinder, (lba / secttors per track) % heads

	mov dh, al ; head, , (lba / secttors per track) / heads

	mov dl, 0 ; drive
	
	pop ax ; sectors to read
	mov ah, 0x02
	int 0x13
	
	popa
	ret

; Stop execution
stop:
	hlt
.halt:
	jmp .halt

	message_welcome db "Welcome to Dummy OS!", 0
	times 510 - ($ - $$) db 0
	db 0xaa, 0x55
	
; dynamic data
buffer: resb 512
db "This is a dummy data",
db "And some more", 0
times 1536 - ($ - $$) db 0
