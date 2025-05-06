cpu 386
bits 16

jmp start

%include "kernel/constants.asm"

;
; Data
cursor_position db 0
text_buffer db 80

;
; Values
msg_welcome db `Shell started\n\0`
command_reboot db `reboot`

start:
    mov ax, ds
    mov es, ax

    mov ah, SYS_INT_CLEAR_SCREEN
    int SYS_INT

    mov ah, SYS_INT_PRINT_STRING
    mov si, msg_welcome
    int SYS_INT

.loop:
    mov ah, SYS_INT_GET_KEYSTROKE
    int SYS_INT

    cmp al, `\r` ; enter
    jne .not_enter
    cmp byte [cursor_position], 0
    je .not_enter

    call parse_command

    mov ah, SYS_INT_PRINT_CHAR
    mov al, `\r`
    int SYS_INT
    mov al, `\n`
    int SYS_INT

    mov byte [cursor_position], 0
    jmp .end

.not_enter:
    cmp byte [cursor_position], 79
    jnb .not_valid

    cmp al, `a`
    jb .not_lower_case
    cmp al, `z`
    ja .not_lower_case
    jmp .valid

.not_lower_case:
    cmp al, `A`
    jb .not_valid
    cmp al, `Z`
    ja .not_valid
    jmp .valid

.not_valid:
    jmp .end

.valid:
    ;mov si, text_buffer
    mov byte si, [cursor_position]
    and si, 0xff
    mov [text_buffer + si], al
    inc byte [cursor_position]
    mov ah, SYS_INT_PRINT_CHAR
    int SYS_INT

.end:
    jmp .loop

parse_command:
    pusha
    
    ; reboot
    mov si, text_buffer
    mov di, command_reboot
    mov cx, 6
    cld
    repe cmpsb
    jne .not_reboot

    mov ah, SYS_INT_REBOOT
    int SYS_INT

.not_reboot:
    popa
    ret