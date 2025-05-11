cpu 386
bits 32
;org 0x1000

%define ADDRESS_TERMINAL 0xb8000

;
; Data
terminal_width dw 80
terminal_height dw 25

cursor_x dw 0
cursor_y dw 0

;
; Initialize the terminal
terminal_init:
    mov ax, TERMINAL_MODE_80x50
    call terminal_set_mode
    ret

;
;
; in
;  al: mode
terminal_set_mode:
    pushad
    mov dx, ax
    call sys_switch_to_v86_mode
    bits 16

    ; 80x25
    cmp dx, 1
    jne .not_80x25
    mov ax, 0x0003
    mov word [terminal_width], 80
    mov word [terminal_height], 25
    int 0x10
    jmp .done

    ; 80x50
.not_80x25:
    cmp dx, 2
    jne .not_80x50
    mov ax, 0x1112
    mov word [terminal_width], 80
    mov word [terminal_height], 50
    int 0x10
    jmp .done

.not_80x50:
    ; invalid

.done:
    
    call sys_switch_to_protected_mode
    bits 32
    popad
    ret

; 
; Print a `\0` terminated string
; in
;  esi: string address
;  al: text attribute
terminal_print_string:
    pushad
    mov bh, al ; keep attribute

.loop:
    lodsb
    mov bl, al ; keep loaded char

    ; End of string ?
    cmp bl, `\0`
    jz .end

    ; New line ?
    cmp bl, `\n`
    jnz .not_new_line
    mov word [cursor_x + 0x1000], 0
    inc word [cursor_y + 0x1000]
    jmp .loop

.not_new_line:
    mov eax, 0
    mov word ax, [cursor_y + 0x1000]
    mul word [terminal_width + 0x1000]
    add word ax, [cursor_x + 0x1000]
    shl ax, 1 ; two bytes per char
    ;add eax, ADDRESS_TERMINAL
    mov byte [ADDRESS_TERMINAL + eax], bl
    mov byte [ADDRESS_TERMINAL + eax + 1], bh

    ; End of line?
    inc word [cursor_x + 0x1000]
    mov word ax, [cursor_x + 0x1000]
    cmp word ax, [terminal_width + 0x1000]
    jb .loop
    
    mov word [cursor_x + 0x1000], 0
    inc word [cursor_y + 0x1000]

    jmp .loop

.end:
    ; Move cursor
    mov eax, 0
    mov word ax, [cursor_y + 0x1000]
    mul word [terminal_width + 0x1000]
    add word ax, [cursor_x + 0x1000]
    mov bx, ax

    ; Move high byte
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al

    mov dx, 0x03d5
    mov al, bh
    out dx, al

    ; Move low byte
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al

    mov dx, 0x03d5
    mov al, bl
    out dx, al

    popad
    ret

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
