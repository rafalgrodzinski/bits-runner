cpu 386
bits 32

%define FAT_BYTES_PER_SECTOR 512
%define FAT_RESERVED_SECTORS_COUNT 1
%define FAT_FATS_COUNT 2
%define FAT_ROOT_DIR_ENTRIES_COUNT 512
%define FAT_SECTORS_PER_FAT 9
%define FAT_SECTORS_PER_TRACK 18
%define FAT_HEADS_COUNT 2

%define FAT_BYTES_PER_ENTRY 32
%define FAT_EOF 0x0ff8
%define FAT_ENTRY_CLUSTER_OFFSET 26
%define FAT_ENTRY_FILE_SIZE_OFFSET 28
%define FAT_FIRST_DATA_SECTOR FAT_RESERVED_SECTORS_COUNT + (FAT_FATS_COUNT * FAT_SECTORS_PER_FAT) + ((FAT_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / FAT_BYTES_PER_SECTOR) - 2
%define FAT_ROOT_DIR_OFFSET FAT_RESERVED_SECTORS_COUNT + FAT_SECTORS_PER_FAT * FAT_FATS_COUNT
%define FAT_ROOT_DIR_SECTORS_COUNT (FAT_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / FAT_BYTES_PER_SECTOR

;
; Messages
msg_error_disk_read_failed db `Failed to read disk!\n\0`

;
; Allocated data
address_fat: dd 0
address_root_dir: dd 0

;
; Initialize fat file system
fat_init:
	pusha

	; load fat
	mov eax, FAT_SECTORS_PER_FAT * FAT_BYTES_PER_SECTOR
	call memory_allocate
	mov [address_fat], edi

	mov eax, FAT_RESERVED_SECTORS_COUNT
	mov ebx, FAT_SECTORS_PER_FAT
	call read_floppy_data

	; load root directory
	mov eax, FAT_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY
	call memory_allocate
	mov [address_root_dir], edi

	mov eax, FAT_ROOT_DIR_OFFSET
	mov ebx, FAT_ROOT_DIR_SECTORS_COUNT
	call read_floppy_data

	popa
	ret

;
; Converts LBA to CHS addressing
; in
;  eax: LBA address
; out
;  ch: cylinder
;  dh: head
;  cl: sector
lba_to_chs:
	push eax
	push bx
	
    mov bx, FAT_SECTORS_PER_TRACK
	div bl
	mov cl, ah
	add cl, 1 ; sector, lba % sectors per track + 1
	
	mov ah, 0
    mov bx, FAT_HEADS_COUNT
	div bl
	mov dh, ah ; head, (lba / secttors per track) % heads
	mov ch, al ; cylinder, (lba / secttors per track) / heads
	
	pop bx
	pop eax
	ret

;
; Read sectors from floppy
; in
;  eax: LBA addressed sector to read
;  ebx: number of sectors to read
;  edi: target address
read_floppy_data:
	pusha

	; convert linear address in eax into es:bx
	push eax ; preserve lba address
	mov eax, edi
	mov edx, 0
	mov esi, 0xffff
	div esi
	mov edi, edx ; preserve address offset
	mov es, ax ; keep address segment
	pop eax

	call lba_to_chs ; convert eax into ch, dh, cl
	mov dl, 0 ; drive number
	mov al, bl ; number of sectors to read
	mov bx, di ; target address from division reminder

	call sys_switch_to_v86_mode
bits 16
	; try reading 3 times
	mov di, 3

.loop:
	mov ah, 0x02
	int 0x13
	jnc .read_successful
	dec di
	jnz .loop

	call sys_switch_to_protected_mode
bits 32
	; Read failed
	mov esi, msg_error_disk_read_failed
	call sys_fatal_error

bits 16
.read_successful:
	call sys_switch_to_protected_mode
bits 32
	popa
	ret

;
; Try finding file entry for a given name
; in
;  esi: file name address
; out
;  edi: found file address
db "BANANA"
fat_file_entry:
	push eax
	push ebx
	push ecx
	push esi

	mov ebx, esi ; preserve
	mov edi, [address_root_dir]
	mov eax, 0 ; current file entry
.loop:
	mov esi, ebx ; restore
	mov ecx, 11 ; 11 chars in file name
	push edi
	repe cmpsb ; Try matching file names
	pop edi
	je .end ; found file

	; Try next entry
	add edi, FAT_BYTES_PER_ENTRY
	inc eax
	cmp eax, FAT_ROOT_DIR_ENTRIES_COUNT
	jl .loop

	; Gone through all file entries, nothing found
	mov edi, 0

.end:
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret

;
; Try getting file size for given file name
; in
;  si: file name address
; out
;  ax: size in bytes
;fat_file_size:
;	push bx
;	push cx
;	push si
;	push di
;
;	mov bx, si ; preserve
;
;	mov ax, [segment_root_dir]
;	mov es, ax
;	mov di, 0
;
;	mov ax, 0 ; current entry count
;
;.loop:
;	mov si, bx
;	mov cx, 11 ; 11 chars in file name
;	push di
;	repe cmpsb ; Try matching file names
;	pop di
;	je .found_file
;
;	; Try next entry
;	add di, FAT_BYTES_PER_ENTRY
;	inc ax
;	cmp ax, FAT_ROOT_DIR_ENTRIES_COUNT
;	jl .loop
;
;	; Gone through all file entries, nothing found
;	mov ax, 0
;	jmp .not_found
;
;.found_file:
;	mov word ax, es:[di + FAT_ENTRY_FILE_SIZE_OFFSET]
;
;.not_found:
;	pop di
;	pop si
;	pop cx
;	pop bx
;	ret

;
; Load file into memory starting with given cluster number
; in
;  ax: fat cluster number
;  es: target segment address
;fat_load_file:
;	pusha
;	push es
;	
;.loop:
;	; Load sector pointed by cluster into memory
;	pusha
;	add ax, FAT_FIRST_DATA_SECTOR ; sector
;	mov bx, 1 ; count
;	call read_floppy_data
;	popa
;	mov cx, es
;	add cx, FAT_BYTES_PER_SECTOR >> 4
;	mov es, cx
;
;	; Load next next fat cluster
;	mov si, 3
;	mul si
;	mov si, 2
;	div si ; Divide by 1.5 since we're extracting 12 bits (1.5 byte)
;	
;	mov gs, [segment_fat]
;	mov si, ax
;	mov ax, gs:[si]
;
;	; Adjust 12 bit to 16 bit
;	or dx, dx
;	jz .even
;.odd:
;	shr ax, 4
;	jmp .next_cluster
;.even:
;	and ax, 0x0fff
;
;.next_cluster:		
;	cmp ax, FAT_EOF ; range 0x0ff8 - 0x0fff marks last fat cluster
;	jb .loop
;
;	pop es
;	popa
;	ret