org 0x200000
cpu 386
bits 32

%include "boot/bios_service_header.asm"

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
    push eax

    ; 80x25
    cmp al, 1
    jne .not_80x25
    mov word [terminal_width], 80
    mov word [terminal_height], 25
    mov ah, BIOS_SERVICE_SET_VIDEO_MODE
    mov al, BIOS_SERVICE_TEXT_MODE_80x25
    call [bios_service]
    jmp .end
.not_80x25:

    ; 80x50
    cmp al, 2
    jne .not_80x50
    mov word [terminal_width], 80
    mov word [terminal_height], 50
    mov ah, BIOS_SERVICE_SET_VIDEO_MODE
    mov al, BIOS_SERVICE_TEXT_MODE_80x50
    call [bios_service]
    jmp .end
.not_80x50:

    ; invalid
.end:
    pop eax
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
    mov ax, [terminal_width]
    mul word [terminal_height]
    mov ecx, eax
    shr ecx, 1 ; half of count of chars

    ; copy eax into [edi+ecx]
    mov eax, ebx
    mov edi, TERMINAL_BUFFER
    rep stosd

    popad
    ret

;
; Scroll down by one line
terminal_scroll_down:
    pushad
    mov bl, al ; preserve

    movzx eax, word [terminal_height]
    sub eax, 1
    mul word [terminal_width]
    shr eax, 1 ; half of count of chars
    mov ecx, eax

    ; destination = buffer
    mov edi, TERMINAL_BUFFER
    ; source = buffer +1 line
    movzx esi, word [terminal_width]
    shl esi, 1
    add esi, TERMINAL_BUFFER
    rep movsd ; move the data

    ; clear bottom line
    movzx eax, word [terminal_height]
    sub eax, 1
    mul word [terminal_width]
    shl eax, 1
    add eax, TERMINAL_BUFFER
    mov edi, eax

    movzx ecx, word [terminal_width]
    shr ecx, 1
    mov eax, TERMINAL_FOREGROUND_GRAY | TERMINAL_BACKGROUND_BLACK
    shl eax, 24
    mov eax, TERMINAL_FOREGROUND_GRAY | TERMINAL_BACKGROUND_BLACK
    shl eax, 8
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
    mov word [cursor_x], 0
    inc word [cursor_y]
    jmp .move_cursor

.not_new_line:
    ; Backspace ?
    cmp ah, `\b`
    jnz .not_backspace
    
    cmp word [cursor_x], 0
    jna .not_overscrolled ; Already in first position

    mov bx, ax ; preserve
    dec word [cursor_x]
    movzx eax, word [cursor_y]
    mul word [terminal_width]
    add ax, [cursor_x]
    shl eax, 1 ; two bytes per char
    mov byte [TERMINAL_BUFFER + eax], 0
    mov [TERMINAL_BUFFER + eax + 1], bl
    jmp .not_overscrolled

.not_backspace:
    mov bx, ax ; preserve
    movzx eax, word [cursor_y]
    mul word [terminal_width]
    add ax, [cursor_x]
    shl eax, 1 ; two bytes per char
    mov [TERMINAL_BUFFER + eax], bh
    mov [TERMINAL_BUFFER + eax + 1], bl

    ; End of line?
    inc word [cursor_x]
    movzx eax, word [cursor_x]
    cmp ax, [terminal_width]
    jb .move_cursor
    
    mov word [cursor_x], 0
    inc word [cursor_y]

.move_cursor:
    ; Check if we've overscrolled
    movzx eax, word [cursor_y]
    cmp ax, [terminal_height]
    jb .not_overscrolled

    call terminal_scroll_down
    dec word [cursor_y]

.not_overscrolled:
    ; Move cursor
    movzx eax, word [cursor_y]
    mul word [terminal_width]
    add ax, [cursor_x]
    mov bx, ax ; keep position

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
    mov bl, al ; keep attribute

.loop:
    lodsb

    ; End of string ?
    cmp al, `\0`
    jz .end

    mov ah, al
    mov al, bl
    call terminal_print_character
    jmp .loop

.end:
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
