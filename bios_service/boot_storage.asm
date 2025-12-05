[org 0x1000]
[cpu 386]
[bits 32]

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

%define FIRST_PARTITION_ENTRY_OFFSET 0x01be
%define SECOND_PARTITION_ENTRY_OFFSET 0x01ce
%define THIRD_PARTITION_ENTRY_OFFSET 0x01de
%define FOURTH_PARTITION_ENTRY_OFFSET 0x01ee
%define PARTITION_ENTRY_START_SECTOR_OFFSET 0x08

;
; Messages
msg_error_disk_read_failed db `Failed to read disk!\n\0`

;
; Allocated data
sectors_per_track: db FAT_SECTORS_PER_TRACK
heads_count: db FAT_HEADS_COUNT
address_fat: dd 0
address_root_dir: dd 0

boot_storage_drive_number: dd 0
boot_storage_partition_first_sector: dd 0
boot_storage_drive_cylinders: dd 0
boot_storage_drive_heads: dd 0
boot_storage_drive_sectors: dd 0

;
; Initialize boot storage handler
; in
;  boot_drive_number
;  boot_partition_entry_adr
%define .boot_drive_number [ebp + 8]
%define .boot_partition_first_sector [ebp + 12]
[bits 32]
boot_storage_init_32:
	push ebp
	mov ebp, esp

	; Store drive number and first sector
	mov eax, .boot_drive_number
	mov [boot_storage_drive_number], eax

	mov eax, .boot_partition_first_sector
	mov [boot_storage_partition_first_sector], eax

	; Get geometry
	call switch_to_v86_mode
[bits 16]

	mov ah, 0x08
	mov edx, .boot_drive_number
	int 0x13

	call switch_to_protected_mode
[bits 32]

	; heads (bits 7:0 of dh)
	shr edx, 8
	and edx, 0xff
	inc edx
	mov [boot_storage_drive_heads], edx

	; sectors (bits 5-0 of cl)
	mov eax, ecx
	and eax, 0x3f
	mov [boot_storage_drive_sectors], eax

	; cylinders (bits 7-6 cl, 7-0 ch)
	mov eax, 0
	mov al, ch
	shr cl, 6
	mov ah, cl
	inc eax
	mov [boot_storage_drive_cylinders], eax

	push dword [boot_storage_drive_number]
	call print_hex_32
	call print_new_line_32

	push dword [boot_storage_partition_first_sector]
	call print_hex_32
	call print_new_line_32

	push dword [boot_storage_drive_cylinders]
	call print_hex_32
	call print_new_line_32

	push dword [boot_storage_drive_heads]
	call print_hex_32
	call print_new_line_32

	push dword [boot_storage_drive_sectors]
	call print_hex_32
	call print_new_line_32

	mov esp, ebp
	pop ebp
	ret 4 * 2
%undef .boot_partition_entry_adr
%undef .boot_drive_number

;
; Read sector from the boot storage device
; in
;  sector_index
;  target_adr
; out
;  eax: read sectors count or 0 on error
%define .sector_index [ebp + 8]
%define .target_address [ebp + 12]
[bits 32]
boot_storage_read_sector_32:
	push ebp
	mov ebp, esp

	; convert LBA address into CHS in ch, dh, cl
	push dword .sector_index
	call boot_storage_lba_to_chs_32

	mov al, 1 ; read single sector
	mov bx, .target_address
	mov dl, [boot_storage_drive_number]
	mov edi, 3 ; try reading 3 times

	call switch_to_v86_mode
[bits 16]

.loop:
	mov ah, 0x02
	int 0x13
	jnc .read_successful
	dec edi
	jnz .loop

	mov eax, 0
	jmp .reading_finished

.read_successful:
	mov eax, 1

.reading_finished:
	call switch_to_protected_mode
[bits 32]
	mov esp, ebp
	pop ebp
	ret 4 * 3
%undef .target_address
%undef .sectors_count
%undef .start_sector

;
; Convert LBA address to CHS address
; in
;  lba
; out
;  cl: cylinder & sector
;  ch: cylinder
;  dh: head
;  cylinder <cl 7-6, ch 7-0>, sector <cl 5-0>, head <dh>
%define .lba [ebp + 8]
[bits 32]
boot_storage_lba_to_chs_32: ; 0x16e6
	push ebp
	mov ebp, esp

	mov dx, 0
	mov ax, .lba

	mov bx, [boot_storage_drive_sectors]
	div bx
	mov cl, dl
	add cl, 1
	and cl, 0x3f ; sector, bits 5-0, lba % sectors per track + 1
	
	mov dx, 0
    mov bx, [boot_storage_drive_heads]
	div bx
	mov dh, dl ; head, (lba / sectors per track) % heads
	mov ch, al ; cylinder, 7-0 (lba / sectors per track) / heads
	shl ah, 6
	or cl, ah ; cylinder, 9-8 (in bits 7-6 of cl, together with sector at 5-0)

	mov esp, ebp
	pop ebp
	ret 4 * 1
%undef .lba

;
; Load file from root directory to a given address
; in
;  file_name_adr
;  target_adr
;  buffer_adr
; out
;  eax: size of loaded file or 0 on failure
%define .file_name_adr [ebp + 8]
%define .target_adr [ebp + 12]
%define .buffer_adr [ebp + 16]
[bits 32]
boot_storage_load_file_32:
	push ebp
	mov ebp, esp

    ;mov edi, BUFFER_ADR + 512
    mov edx, .drive_number
    call boot_storage_fat_init_32

	mov esi, .file_name_adr
	call fat_file_entry

	mov esp, ebp
	pop ebp
	ret 4 * 2
%undef .buffer_adr
%undef .target_adr
%undef .file_name_adr

;
; Initialize fat file system
; in
;  edi: fat buffer address
;  dl: drive number
[bits 32]
boot_storage_fat_init_32:
	pusha

	mov [address_fat], edi

	; Read drive CHS geometry if HDD
	cmp dl, 0x80 ; first hard disk number
	jb .skip_chs_detection
	push edx
	call switch_to_v86_mode
bits 16
	mov ah, 0x08
	int 0x13
	and cl, 0x3f ; only bits 5-0 are used (7-6 are used fore cylinders)
	mov [sectors_per_track], cl
	mov [heads_count], dh
	inc byte [heads_count]

	call switch_to_protected_mode
bits 32
	pop edx
.skip_chs_detection:

	; load fat
	mov edi, [address_fat]
	mov eax, FAT_RESERVED_SECTORS_COUNT
	mov ebx, FAT_SECTORS_PER_FAT
	call read_sectors

	; load root directory
	add edi, FAT_SECTORS_PER_FAT * FAT_BYTES_PER_SECTOR
	mov [address_root_dir], edi

	mov eax, FAT_ROOT_DIR_OFFSET
	mov ebx, FAT_ROOT_DIR_SECTORS_COUNT
	call read_sectors

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
	
    mov bx, [sectors_per_track]
	div bl
	mov cl, ah
	add cl, 1 ; sector, lba % sectors per track + 1
	
	mov ah, 0
    mov bx, [heads_count]
	div bl
	mov dh, ah ; head, (lba / secttors per track) % heads
	mov ch, al ; cylinder, (lba / secttors per track) / heads
	
	pop bx
	pop eax
	ret

;
; Read sectors from floppy
; in
;  eax: LBA address of the first sector
;  ebx: number of sectors to read
;  edi: target address
;  dl: drive number
read_sectors:
	pusha

	; convert linear address in eax into es:bx
	push edx ; preserve disk number
	push eax ; preserve lba address
	mov eax, edi
	mov edx, 0
	mov esi, 0xffff
	div esi
	mov edi, edx ; preserve address offset
	mov es, ax ; keep address segment
	pop eax
	pop edx

	call lba_to_chs ; convert eax into ch, dh, cl
	mov al, bl ; number of sectors to read
	mov bx, di ; target address from division reminder

	call switch_to_v86_mode
bits 16
	; try reading 3 times
	mov di, 3

.loop:
	mov ah, 0x02
	int 0x13
	jnc .read_successful
	dec di
	jnz .loop

	call switch_to_protected_mode
bits 32
	; Read failed
	mov esi, msg_error_disk_read_failed
	;call sys_fatal_error
	.h:
	jmp .h

bits 16
.read_successful:
	call switch_to_protected_mode
bits 32
	popa
	ret

;
; Try finding file entry for a given name
; in
;  esi: file name address
; out
;  edi: found file address
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
; Try getting file size for given file entry
; in
;  esi: file entry address
; out
;  eax: size in bytes
fat_file_size:
	mov eax, [esi + FAT_ENTRY_FILE_SIZE_OFFSET]
	ret

;
; Load file into memory for given file entry
; in
;  esi: fat entry address
;  edi: target address
;  ebx: 16 bit buffer address
;  dl: drive number
fat_load_file:
	pusha
	
	movzx eax, word [esi + FAT_ENTRY_CLUSTER_OFFSET]
	mov esi, edx ; preserve drive number
	mov edx, ebx
.loop:
	; Load sector pointed by cluster into memory
	push eax
	add eax, FAT_FIRST_DATA_SECTOR ; sector
	mov ebx, 1 ; count
	push edi
	mov edi, edx
	push edx ; dl should contain drive number
	mov edx, esi
	call read_sectors
	pop edx
	pop edi

	; move to target address if different from temporary buffer
	cmp edi, edx
	je .no_buffer_copy

	mov ecx, 0
.copy_loop:

	mov al, [edx + ecx]
	mov [edi], al
	inc edi

	inc ecx
	cmp ecx, 512
	jl .copy_loop

.no_buffer_copy:
	pop eax
	push edx
	; Load next next fat cluster
	mov ebx, 3
	mul ebx
	mov ebx, 2
	div ebx ; Divide by 1.5 since we're extracting 12 bits (1.5 byte)
	
	mov ebx, [address_fat]
	add ebx, eax
	movzx eax, word [ebx]

	; Adjust 12 bit to 16 bit
	or edx, edx
	jz .even
.odd:
	shr eax, 4
	jmp .next_cluster
.even:
	and eax, 0x0fff

.next_cluster:
	pop edx
	cmp eax, FAT_EOF ; range 0x0ff8 - 0x0fff marks last fat cluster
	jb .loop

	popa
	ret