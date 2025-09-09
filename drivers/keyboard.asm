org 0x80000000
cpu 386
bits 32

%define KEYBOARD_CMD_PORT 0x64
%define KEYBOARD_DATA_PORT 0x60

%define KEY_L_SHIFT 0x2a
%define KEY_R_SHIFT 0x36

keyboard_status: times 128 db 0
pressedAcii: db 0

keyboard_ascii_map:
db 0 ; 0x00 unused
db 0 ; 0x01 esc
db `1` ; 0x02
db `2` ; 0x03
db `3` ; 0x04
db `4` ; 0x05
db `5` ; 0x06
db `6` ; 0x07
db `7` ; 0x08
db `8` ; 0x09
db `9` ; 0x0a
db `0` ; 0x0b
db `-` ; 0x0c
db `=` ; 0x0d
db `\b` ; 0x0e
db `\t` ; 0x0f
db `q` ; 0x10
db `w` ; 0x11
db `e` ; 0x12
db `r` ; 0x13
db `t` ; 0x14
db `y` ; 0x15
db `u` ; 0x16
db `i` ; 0x17
db `o` ; 0x18
db `p` ; 0x19
db `[` ; 0x1a
db `]` ; 0x1b
db `\n` ; 0x1c
db 0 ; 0x1d L Ctrl
db `a` ; 0x1e
db `s` ; 0x1f
db `d` ; 0x20
db `f` ; 0x21
db `g` ; 0x22
db `h` ; 0x23
db `j` ; 0x24
db `k` ; 0x25
db `l` ; 0x26
db `;` ; 0x27
db `'` ; 0x28
db `\`` ; 0x29
db 0 ; 0x2a L Shift
db `\\` ; 0x2b
db `z` ; 0x2c
db `x` ; 0x2d
db `c` ; 0x2e
db `v` ; 0x2f
db `b` ; 0x30
db `n` ; 0x31
db `m` ; 0x32
db `,` ; 0x33
db `.` ; 0x34
db `/` ; 0x35
db 0 ; 0x36 R shift
db 0 ; 0x37 ?
db 0 ; 0x38 ?
db ` ` ; 0x39

keyboard_shifted_ascii_map:
db 0 ; 0x00 unused
db 0 ; 0x01 esc
db `!` ; 0x02
db `@` ; 0x03
db `#` ; 0x04
db `$` ; 0x05
db `%` ; 0x06
db `^` ; 0x07
db `&` ; 0x08
db `*` ; 0x09
db `(` ; 0x0a
db `)` ; 0x0b
db `_` ; 0x0c
db `+` ; 0x0d
db `\b` ; 0x0e
db `\t` ; 0x0f
db `Q` ; 0x10
db `W` ; 0x11
db `E` ; 0x12
db `R` ; 0x13
db `T` ; 0x14
db `Y` ; 0x15
db `U` ; 0x16
db `I` ; 0x17
db `O` ; 0x18
db `P` ; 0x19
db `{` ; 0x1a
db `}` ; 0x1b
db `\n` ; 0x1c
db 0 ; 0x1d L Ctrl
db `A` ; 0x1e
db `S` ; 0x1f
db `D` ; 0x20
db `F` ; 0x21
db `G` ; 0x22
db `H` ; 0x23
db `I` ; 0x24
db `J` ; 0x25
db `K` ; 0x26
db `:` ; 0x27
db `"` ; 0x28
db `~` ; 0x29
db 0 ; 0x2a L Shift
db `|` ; 0x2b
db `Z` ; 0x2c
db `X` ; 0x2d
db `C` ; 0x2e
db `V` ; 0x2f
db `B` ; 0x30
db `N` ; 0x31
db `M` ; 0x32
db `<` ; 0x33
db `>` ; 0x34
db `?` ; 0x35
db 0 ; 0x36 R shift
db 0 ; 0x37 ?
db 0 ; 0x38 ?
db ` ` ; 0x39

;
; Entry for the keyboard handler routine
keyboard_interrupt_handler:
    ; check if we have data
    in al, KEYBOARD_CMD_PORT
    test al, 00000010b
    jnz .end

    in al, KEYBOARD_DATA_PORT
    test al, 0x80 ; is pressed ?
    je .pressed

.released:
    and eax, 0x7f
    cmp byte [keyboard_status + eax], 1
    jne .end ; no state change
    mov byte [keyboard_status + eax], 0
    jmp .end

.pressed:
    and eax, 0x7f ; clear pressed bit
    cmp byte [keyboard_status + eax], 0
    jne .end ; no state change
    mov byte [keyboard_status + eax], 1

    ; Check if we're in map's range
    cmp eax, keyboard_shifted_ascii_map - keyboard_ascii_map
    jg .end

    ; Convert to ASCII
    cmp byte [keyboard_status + KEY_L_SHIFT], 1
    je .shifted
    cmp byte [keyboard_status + KEY_R_SHIFT], 1
    je .shifted
    jmp .not_shifted

.shifted:
    mov ah, [keyboard_shifted_ascii_map + eax]
    cmp ah, 0
    jne .converted
    jmp .end

.not_shifted:
    mov ah, [keyboard_ascii_map + eax]
    cmp ah, 0
    jne .converted
    jmp .end

.converted:
    ; Store calculated ASCII value
    mov [pressedAcii], ah

.end:
    ret