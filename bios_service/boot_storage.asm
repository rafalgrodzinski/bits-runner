[org 0x1000]
[cpu 386]
[bits 32]

%define FAT_BYTES_PER_SECTOR 512
%define FAT_RESERVED_SECTORS_COUNT 1
%define FAT_FATS_COUNT 2
%define FAT_ROOT_DIR_ENTRIES_COUNT 512
%define FAT_SECTORS_PER_FAT 9

%define FAT_BYTES_PER_ENTRY 32
%define FAT_EOF 0x0ff8
%define FAT_ENTRY_CLUSTER_OFFSET 26
%define FAT_ENTRY_FILE_SIZE_OFFSET 28
%define FAT_FIRST_DATA_SECTOR FAT_RESERVED_SECTORS_COUNT + (FAT_FATS_COUNT * FAT_SECTORS_PER_FAT) + ((FAT_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / FAT_BYTES_PER_SECTOR)
%define FAT_ROOT_DIR_OFFSET FAT_RESERVED_SECTORS_COUNT + FAT_SECTORS_PER_FAT * FAT_FATS_COUNT
%define FAT_ROOT_DIR_SECTORS_COUNT (FAT_ROOT_DIR_ENTRIES_COUNT * FAT_BYTES_PER_ENTRY) / FAT_BYTES_PER_SECTOR

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

	;push dword [boot_storage_drive_number]
	;call print_hex_32
	;call print_new_line_32

	;push dword [boot_storage_partition_first_sector]
	;call print_hex_32
	;call print_new_line_32

	;push dword [boot_storage_drive_cylinders]
	;call print_hex_32
	;call print_new_line_32

	;push dword [boot_storage_drive_heads]
	;call print_hex_32
	;call print_new_line_32

	;push dword [boot_storage_drive_sectors]
	;call print_hex_32
	;call print_new_line_32
	;call print_new_line_32

	mov esp, ebp
	pop ebp
	ret 4 * 2
%undef .boot_partition_entry_adr
%undef .boot_drive_number

;
; Read sectors from the boot storage device
; in
;  first_sector
;  sectors_count
;  target_adr
; out
;  eax: read sectors count or 0 on error
%define .first_sector [ebp + 8]
%define .sectors_count [ebp + 12]
%define .target_address [ebp + 16]
[bits 32]
boot_storage_read_sectors_32:
	push ebp
	mov ebp, esp

	;push dword .first_sector
	;call print_hex_32
	;call print_new_line_32

	;push dword .sectors_count
	;call print_hex_32
	;call print_new_line_32

	;push dword .target_address
	;call print_hex_32
	;call print_new_line_32

	;call print_new_line_32

	; convert LBA address into CHS in ch, dh, cl
	push dword .first_sector
	call boot_storage_lba_to_chs_32

	mov al, .sectors_count ; read single sector
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
%undef .first_sector

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

	; load fat & root directory
	mov eax, .buffer_adr
	add eax, 0x200
	push eax ; fat_buffer_adr
    call boot_storage_fat_load_32

	; find file entry
	mov eax, .buffer_adr
	add eax, 0x200
	add eax, FAT_SECTORS_PER_FAT * FAT_BYTES_PER_SECTOR
	push eax ; root_dir_adr
	push dword .file_name_adr ; file_name_adr
	call boot_storage_find_fat_file_entry_adr_32

	cmp eax, 0 ; return if nothing was found
	js .end

	push dword [eax + FAT_ENTRY_FILE_SIZE_OFFSET] ; keep file size
	movzx eax, word [eax + FAT_ENTRY_CLUSTER_OFFSET] ; and get the initial cluster

	; load file
	push dword .buffer_adr ; buffer_adr
	push dword .target_adr ; target_adr
	mov ebx, .buffer_adr
	add ebx, 0x200
	push ebx ; fat_adr
	push eax ; first_cluster
	call boot_storage_read_clusters_32

	pop eax ; restore file size

.end:
	mov esp, ebp
	pop ebp
	ret 4 * 3
%undef .buffer_adr
%undef .target_adr
%undef .file_name_adr

;
; Load fat file system
; in
;  fat_buffer_adr
[bits 32]
%define .fat_buffer_adr [ebp + 8]
boot_storage_fat_load_32:
	push ebp
	mov ebp, esp

	; load fat
	push dword .fat_buffer_adr ; target_adr
	push FAT_SECTORS_PER_FAT ; sectors_count
	mov eax, [boot_storage_partition_first_sector]
	add eax, FAT_RESERVED_SECTORS_COUNT
	push eax; first_sector
	call boot_storage_read_sectors_32

	; load root directory
	mov eax, .fat_buffer_adr
	add eax, FAT_SECTORS_PER_FAT * FAT_BYTES_PER_SECTOR
	push eax ; target_adr
	push dword FAT_ROOT_DIR_SECTORS_COUNT ; sectors_count
	push dword FAT_ROOT_DIR_OFFSET ; first_sector
	call boot_storage_read_sectors_32

	mov esp, ebp
	pop ebp
	ret 4 * 1
%undef .fat_buffer_adr

;
; Try finding file entry for a given name
; in
;  file_name_adr
;  root_dir_adr
; out
;   eax: address of file entry
%define .file_name_adr [ebp + 8]
%define .root_dir_adr [ebp + 12]
boot_storage_find_fat_file_entry_adr_32:
	push ebp
	mov ebp, esp

	mov edi, .root_dir_adr
	xor eax, eax ; current file entry
.loop:
	mov esi, .file_name_adr
	mov ecx, 11 ; 11 chars in file name
	push edi
	repe cmpsb ; Try matching file names
	pop edi
	je .found_file ; entry found

	; Try next entry
	add edi, FAT_BYTES_PER_ENTRY
	inc eax
	cmp eax, FAT_ROOT_DIR_ENTRIES_COUNT
	jl .loop

	; Gone through all file entries, nothing found
	xor eax, eax
	jmp .end

.found_file:
	mov eax, edi

.end:
	mov esp, ebp
	pop ebp
	ret 4 * 2
%undef .root_dir_adr
%undef .file_name_adr

;
; Read linked clusters into a given adress
; in
;  first_cluster
;  fat_adr
;  target_adr
;  buffer_adr
%define .first_cluster [ebp + 8]
%define .fat_adr [ebp + 12]
%define .target_adr [ebp + 16]
%define .buffer_adr [ebp + 20]
boot_storage_read_clusters_32:
	push ebp
	mov ebp, esp

	mov eax, .first_cluster
	; mul sectors per cluster

.loop:
	;push eax
	;push eax
	;call print_hex_32
	;call print_new_line_32
	;pop eax

	; Calculate sector number (sector - 2) * sectors_per_cluster + data start offset + parition start offset
	push eax
	sub eax, 2
	add eax, FAT_FIRST_DATA_SECTOR

	; read sector
	push dword .buffer_adr ; target_address
	push dword 1 ; sectors_count
	push eax ; first_sector
	call boot_storage_read_sectors_32

	; copy data from buffer into target
	xor ecx, ecx
	mov edi, .target_adr
	mov esi, .buffer_adr
.copy_loop:
	mov al, [esi + ecx]
	mov [edi + ecx], al
	inc ecx
	cmp ecx, 512
	jb .copy_loop

	add dword .target_adr, 512

	; Load next cluster number
	pop eax ; restore cluster number

	mov ebx, 3
	mul ebx
	mov ebx, 2
	div ebx ; Multiply by 1.5 since we're extracting 12 bits (1.5 byte)
	add eax, .fat_adr

	movzx eax, word [eax]
	; Adjust 12 bit to 16 bit
	or edx, edx
	jz .even
.odd:
	shr eax, 4
	jmp .next_cluster
.even:
	and eax, 0x0fff

.next_cluster:
	cmp eax, 0x0ff8 ; range 0x0ff8 - 0x0fff marks the last cluster
	jb .loop

.end:
	mov esp, ebp
	pop ebp
	ret 4 * 4
%undef .buffer_adr
%undef .target_adr
%undef .fat_adr
%undef .first_cluster