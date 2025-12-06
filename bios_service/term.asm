;
; Print string
; in
;  si: string address
[bits 16]
term_print_string_16:
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
	popa
	ret

;
; Prints new line
[bits 32]
term_print_new_line_32:
    call switch_to_v86_mode_32
[bits 16]

    call term_print_new_line_16

    call switch_to_protected_mode_16
[bits 32]
    ret

;
; Prints a new line
[bits 16]
term_print_new_line_16:
	mov bx, 0
	mov ah, 0x0e

	mov al, 0x0d ; CR
	int 0x10
	mov al, 0x0a ; LF
	int 0x10

    ret

;
; Print integer
;  eax: integer to print
[bits 16]
term_print_int_16:
	pusha

	mov ecx, 0
process_digit:
	inc ecx
	mov edx, 0
	mov ebx, 10
	idiv ebx
	add dx, "0"
	push dx
	cmp eax, 0
	jnz process_digit

print_digit:
	mov esi, esp
	call term_print_string_16
    add sp, 2
    loop print_digit

	popa
	ret

;
; in
;  value
%define .value [ebp + 8]
[bits 32]
term_print_hex_32:
    push ebp
    mov ebp, esp

    mov eax, .value

    call switch_to_v86_mode_32
[bits 16]

    call term_print_hex_16

    call switch_to_protected_mode_16
[bits 32]

    mov esp, ebp
    pop ebp
    ret 4 * 1

;
; Print hexadeciaml value
; in
;  eax: integer to print
[bits 16]
term_print_hex_16:
    pusha

    mov ecx, 0 ; Count number of digits
.loop_process_digit:
    inc ecx
    mov edx, 0
    mov esi, 16
    div esi

    cmp dx, 10 ; Check if we should add `0` or `A`
    jae .above_9
    add dx, `0`
    jmp .digit_converted

.above_9:
    add dx, `a` - 10

.digit_converted:
    push dx ; Place converted digit on stack

    cmp eax, 0 ; Check if we're out of digits
	jnz .loop_process_digit

    ; Check if we have even numbr of digits, if not append one
    test cx, 0x01
    je .print_pref
	push 0x0030
	inc cx

.print_pref:
	push 0x0000
	push 0x7830
	mov si, sp
	call term_print_string_16
	add sp, 4

.loop_print_digit:
	mov si, sp
	call term_print_string_16
	add sp, 2
	loop .loop_print_digit

    popa
    ret