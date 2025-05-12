cpu 386
bits 32

%define TERMINAL_BUFFER 0xb8000

;
; Data
terminal_width dw 0
terminal_height dw 0

cursor_x dw 0
cursor_y dw 0

;
; Initialize the terminal
terminal_init:
    mov al, TERMINAL_MODE_80x25
    call terminal_set_mode
    mov al, TERMINAL_BACKGROUND_BLACK + TERMINAL_FOREGROUND_GRAY
    call terminal_clear
    ret

;
; Change text mode
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
    mov word [terminal_width + ADDRESS_KERNEL], 80
    mov word [terminal_height + ADDRESS_KERNEL], 25
    int 0x10
    jmp .done

    ; 80x50
.not_80x25:
    cmp dx, 2
    jne .not_80x50
    mov ax, 0x1112
    mov word [terminal_width + ADDRESS_KERNEL], 80
    mov word [terminal_height + ADDRESS_KERNEL], 50
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
; Clears the screen with a given attribute
; in
;  al: background's attribute
terminal_clear:
    pushad
    mov bl, al
    shl ebx, 24
    mov bh, al ; preserve in bx <attrib><empty><attrib><empty>

    mov eax, 0
    mov ax, [terminal_width + ADDRESS_KERNEL]
    mul word [terminal_height + ADDRESS_KERNEL]
    mov ecx, eax
    shr ecx, 1 ; half of count of chars

    ; copy eax into [edi+ecx]
    mov eax, ebx
    mov edi, TERMINAL_BUFFER
    rep stosd

    popad
    ret

;
; Print a single character to terminal at current position
; in
;  ah: ASCII character to print
;  al: attribute
terminal_print_character:
    pusha

    ; New line ?
    cmp ah, `\n`
    jnz .not_new_line
    mov word [cursor_x + ADDRESS_KERNEL], 0
    inc word [cursor_y + ADDRESS_KERNEL]
    jmp .move_cursor

.not_new_line:
    mov bx, ax ; preserve
    movzx word ax, [cursor_y + ADDRESS_KERNEL]
    mul word [terminal_width + ADDRESS_KERNEL]
    add word ax, [cursor_x + ADDRESS_KERNEL]
    shl ax, 1 ; two bytes per char
    mov byte [TERMINAL_BUFFER + eax], bh
    mov byte [TERMINAL_BUFFER + eax + 1], bl

    ; End of line?
    inc word [cursor_x + ADDRESS_KERNEL]
    mov word ax, [cursor_x + ADDRESS_KERNEL]
    cmp word ax, [terminal_width + ADDRESS_KERNEL]
    jb .move_cursor
    
    mov word [cursor_x + ADDRESS_KERNEL], 0
    inc word [cursor_y + ADDRESS_KERNEL]

.move_cursor:
    ; Move cursor
    movzx word ax, [cursor_y + ADDRESS_KERNEL]
    mul word [terminal_width + ADDRESS_KERNEL]
    add word ax, [cursor_x + ADDRESS_KERNEL]
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

    popa
    ret

; 
; Print a `\0` terminated string at current position
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
    mov byte [TERMINAL_BUFFER + eax], bl
    mov byte [TERMINAL_BUFFER + eax + 1], bh

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
; Print value in hexadeciaml format at current position
; in
;  al: text attribute
;  ebx: value to print 
terminal_print_hex:
    pusha
    xchg eax, ebx ; preserve attrib in ebx
    mov ecx, 0 ; Count number of digits

.loop_process_digit:
    inc ecx
    mov edx, 0
    mov esi, 16
    div esi

    cmp edx, 10 ; Check if we should add `0` or `A`
    jae .above_9
    add edx, `0`
    jmp .digit_converted

.above_9:
    add edx, `a` - 10

.digit_converted:
    push edx ; Place converted digit on stack

    cmp eax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

    movzx eax, bl ; restore preserved attribute
    ; First print the prefix
    mov ah, `0`
    call terminal_print_character
    mov ah, `x`
    call terminal_print_character
    ; Check if we have even numbr of digits, if not append one
    test cx, 0x01
    je .loop_print_digit
    mov ah, `0`
    call terminal_print_character

.loop_print_digit:
    pop eax
    mov ah, al
    mov al, bl
    call terminal_print_character

    dec ecx
    jnz .loop_print_digit

    popa
    ret
