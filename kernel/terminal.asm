cpu 386
bits 16

;
; Print a single character to terminal
; in
;  ah: ASCII character to print
print_character:
    pusha
    mov ah, 0x0e
    int 0x10
    popa
    ret

; 
; Print a `\0` terminated string
; in
;  ds:si - Address
print_string:
    pusha
    mov ah, 0x0e

.loop:
    lodsb

    ; End of string
    cmp al, `\0`
    jz .end

    ; New line
    cmp al, `\n`
    jnz .not_new_line

    mov al, 0xd ; `\r` CR
    int 0x10

    mov al, 0xa ; `\n` LF
    int 0x10

    jmp .loop

.not_new_line:
    int 0x10
    jmp .loop

.end:
    popa
    ret

;
; Print an unsigned integer
; in
;  ax - Value
print_uint:
	pusha
	mov cx, 0 ; Count number of digits

.loop_process_digit:
	inc cx
    mov dx, 0
	mov bx, 10
	div bx
	add dx, `0` ; Convert reminder of the division into an ASCII char
	push dx ; and place it on stack

    cmp ax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

.loop_print_digit:
    pop ax
    mov ah, 0x0e
	int 0x10

    dec cx
    jnz .loop_print_digit

	popa
	ret

;
; Print value in hexadeciaml format
; in
;  ax - Value
print_hex:
    pusha
    mov cx, 0 ; Count number of digits

.loop_process_digit:
    inc cx
    mov dx, 0
    mov bx, 16 ; 
    div bx

    cmp dx, 10 ; Check if we should add `0` or `A`
    jae .above_9
    add dx, `0`
    jmp .digit_converted

.above_9:
    add dx, `a` - 10

.digit_converted:
    push dx ; Place converted digit on stack

    cmp ax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

    mov ah, 0x0e
    ; First print the prefix
    mov al, `0`
	int 0x10
    mov al, `x`
    int 0x10

    ; Check if we have even numbr of digits, if not append one
    test cx, 0x01
    je .loop_print_digit
    mov al, `0`
    int 0x10

.loop_print_digit:
    pop ax
    mov ah, 0x0e
	int 0x10

    dec cx
    jnz .loop_print_digit

    popa
    ret

get_keystroke:
    mov ah, 0x00
    int 0x16
    ret

terminal_clear_screen:
    push ax
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    pop ax
    ret
