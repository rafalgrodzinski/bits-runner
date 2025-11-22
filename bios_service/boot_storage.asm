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

;
; Messages
msg_error_disk_read_failed db `Failed to read disk!\n\0`

;
; Allocated data
sectors_per_track: db FAT_SECTORS_PER_TRACK
heads_count: db FAT_HEADS_COUNT
address_fat: dd 0
address_root_dir: dd 0


boot_drive_heads dd 0
boot_drive_sectors dd 0
boot_drive_cylinders dd 0
boot_drive_first_sector

;
; Initialize boot storage handler
; in
;  boot_drive_number
;  boot_partition_entry_adr
%define .boot_drive_number [ebp + 8]
%define .boot_partition_entry_adr [ebp + 12]
[bits 32]
boot_storage_init_32:
	push ebp
	mov ebp, esp

	; Get geometry
	call switch_to_v86_mode
[bits 16]
	mov ah, 0x08
	mov edx, .boot_drive_number
	int 0x13

	; heads (bits 7:0 of edx)
	shr edx, 8
	and edx, 0xff
	inc edx
	mov [boot_drive_heads], eax

	; sectors (bits 5-0 of ecx)
	mov eax, ecx
	and eax, 0x3f
	mov [boot_drive_sectors], eax

	; cylinders (bits 7-6 cl, 7-0 ch)
	mov eax, 0
	mov al, ch
	shr cl, 6
	mov ah, cl
	inc eax
	mov [boot_drive_cylinders], eax

	; Get first sector (first sector of a partition or 0 if not using mbr)
	

	mov esp, ebp
	pop ebp
%undef .boot_partition_entry_adr
%undef .boot_drive_number

;
; Load file from root directory to a given address
; in
;  drive_number
;  file_name_adr
;  target_adr
; out
;  eax: 0 if success
%define .drive_number [ebp + 8]
%define .partition_entry_adr [ebp + 12]
%define .file_name_adr [ebp + 16]
%define .target_adr [ebp + 20]
[bits 32]
storage_load_file:
	push ebp
	mov ebp, esp

    mov edi, BUFFER_ADR + 512
    mov edx, .drive_number
    call fat_init

	mov esi, .file_name_adr
	call fat_file_entry

	mov esp, ebp
	pop ebp
	ret 4 * 3
%undef .target_adr
%undef .file_name_adr
%undef .partition_entry_adr
%undef .drive_number

;
; Initialize fat file system
; in
;  edi: fat buffer address
;  dl: drive number
fat_init:
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