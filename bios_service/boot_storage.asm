[org 0x1000]
[cpu 386]
[bits 32]

; predefined values
%define FS_TYPE_FAT12 12
%define FS_TYPE_FAT16 16

%define FAT_BYTES_PER_ENTRY 0x20
%define FAT12_EOF 0x0ff8
%define FAT16_EOF 0xfff8

; file entry offsets
%define FAT_ENTRY_CLUSTER_OFFSET 0x1a ; 2 bytes
%define FAT_ENTRY_FILE_SIZE_OFFSET 0x1c ; 4 bytes
%define FAT_FS_ID_OFFSET 0x36 ; 8 bytes

; fat header offsets
%define FAT_BYTES_PER_SECTOR_OFFSET 0x0b ; 2 bytes
%define FAT_SECTORS_PER_CLUSTER_OFFSET 0x0d ; 1 byte
%define FAT_RESERVED_SECTORS_COUNT_OFFSET 0x0e ; 1 byte
%define FAT_FATS_COUNT_OFFSET 0x10 ; 1 byte
%define FAT_ROOT_DIR_ENTRIES_COUNT_OFFSET 0x11 ; 2 bytes
%define FAT_SECTORS_PER_FAT_OFFSET 0x16 ; 2 bytes

; from fat header
boot_storage_fat_bytes_per_sector: dd 0
boot_storage_fat_sectors_per_cluster: dd 0
boot_storage_fat_reserved_sectors_count: dd 0
boot_storage_fat_fats_count: dd 0
boot_storage_fat_root_dir_entries_count: dd 0
boot_storage_fat_sectors_per_fat: dd 0

; calclulated
boot_storage_fat_fat_first_sector: dd 0
boot_storage_fat_root_dir_sectors_count: dd 0
boot_storage_fat_root_dir_first_sector: dd 0
boot_storage_fat_first_data_sector: dd 0

boot_storage_fs_type: dd 0

; from boot & bios
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
%define .args_count 2
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
	call switch_to_v86_mode_32
[bits 16]

	mov ah, 0x08
	mov edx, .boot_drive_number
	int 0x13

	call switch_to_protected_mode_16
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

	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .boot_partition_entry_adr
%undef .boot_drive_number
%undef .args_count

;
; Read sectors from the boot storage device
; in
;  first_sector
;  sectors_count
;  target_adr
;  buffer_adr
; out
;  eax: read sectors count or 0 on error
%define .args_count 4
%define .first_sector [ebp + 8]
%define .sectors_count [ebp + 12]
%define .target_adr [ebp + 16]
%define .buffer_adr [ebp + 20]
[bits 32]
boot_storage_read_sectors_32:
	push ebp
	mov ebp, esp

	mov ecx, .sectors_count

.sectors_loop:
	push ecx

	; read given sector into a temp buffer
	push dword .buffer_adr
	push dword .first_sector
	call boot_storage_read_sector_32
	cmp eax, 0
	jz .end

	; copy data from buffer into target address
	cld
	mov ecx, [boot_storage_fat_bytes_per_sector]
	shr ecx, 2 ; we move 4 bytes at a time, so divide by 4
	mov esi, .buffer_adr
	mov edi, .target_adr
	rep movsd
	mov .target_adr, edi ; point target address to the next area

	inc dword .first_sector ; move the next input sector

	pop ecx
	loop .sectors_loop

.end:
	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .buffer_adr
%undef .target_adr
%undef .sectors_count
%undef .first_sector
%undef .args_count

;
; Read singe sector from the boot storage device
; in
;  sector
;  target_adr (within the first memory segment)
; out
;  eax: read sectors count (1) or 0 on error
%define .args_count 2
%define .sector [ebp + 8]
%define .target_adr [ebp + 12]
[bits 32]
boot_storage_read_sector_32:
	push ebp
	mov ebp, esp

	; convert LBA address into CHS in ch, dh, cl
	push dword .sector
	call boot_storage_lba_to_chs_32

	mov al, 1 ; read single sector
	mov bx, .target_adr
	mov dl, [boot_storage_drive_number]
	mov edi, 3 ; try reading 3 times

	call switch_to_v86_mode_32
[bits 16]

.retry_loop:
	mov ah, 0x02
	int 0x13
	jnc .read_successful
	dec edi
	jnz .retry_loop
	jmp .read_failed

.read_successful:
	mov eax, 1
	jmp .end

.read_failed:
	mov eax, 0

.end:
	call switch_to_protected_mode_16
[bits 32]

	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .target_adr
%undef .sector
%undef .args_count

;
; Convert LBA address to CHS address
; in
;  lba
; out
;  cl: cylinder & sector
;  ch: cylinder
;  dh: head
;  cylinder <cl 7-6, ch 7-0>, sector <cl 5-0>, head <dh>
%define .args_count 1
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
	ret 4 * .args_count
%undef .lba
%undef .args_count

;
; Load file from root directory to a given address
; in
;  file_name_adr
;  target_adr
;  buffer_adr
; out
;  eax: size of loaded file or 0 on failure
%define .args_count 3
%define .file_name_adr [ebp + 8]
%define .target_adr [ebp + 12]
%define .buffer_adr [ebp + 16]
[bits 32]
boot_storage_load_file_32:
	push ebp
	mov ebp, esp

	; load fat & root directory
	push dword .buffer_adr ; buffer_adr
	mov eax, .buffer_adr
	add eax, 0x200
	push eax ; fat_adr
    call boot_storage_fat_init_32

	cmp eax, 0
	jz .end

	; find file entry
	mov eax, [boot_storage_fat_sectors_per_fat]
	mul dword [boot_storage_fat_bytes_per_sector]
	add eax, .buffer_adr
	add eax, 0x200
	push eax ; root_dir_adr
	push dword .file_name_adr ; file_name_adr
	call boot_storage_find_fat_file_entry_adr_32

	cmp eax, 0 ; return if nothing was found
	jz .end

	push dword [eax + FAT_ENTRY_FILE_SIZE_OFFSET] ; keep file size
	movzx eax, word [eax + FAT_ENTRY_CLUSTER_OFFSET] ; get the first cluster

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
	ret 4 * .args_count
%undef .buffer_adr
%undef .target_adr
%undef .file_name_adr
%undef .args_count

;
; Load fat file system
; in
;  fat_adr
;  buffer_adr
; out
;  eax: 1 succes, 0 failure
[bits 32]
%define .args_count 2
%define .fat_adr [ebp + 8]
%define .buffer_adr [ebp + 12]
boot_storage_fat_init_32:
	push ebp
	mov ebp, esp

	; read fat info
	push dword .buffer_adr ; buffer_adr
	push dword .buffer_adr ; target_adr
	push dword 1 ;sectors_count
	push dword [boot_storage_partition_first_sector] ; first_sector
	call boot_storage_read_sectors_32

	; fat_bytes_per_sector
	mov ebx, .buffer_adr
	movzx eax, word [ebx + FAT_BYTES_PER_SECTOR_OFFSET]
	mov [boot_storage_fat_bytes_per_sector], eax

	; fat_sectors_per_cluster
	mov ebx, .buffer_adr
	movzx eax, byte [ebx + FAT_SECTORS_PER_CLUSTER_OFFSET]
	mov [boot_storage_fat_sectors_per_cluster], eax

	; fat_reserved_sectors_count
	mov ebx, .buffer_adr
	movzx eax, byte [ebx + FAT_RESERVED_SECTORS_COUNT_OFFSET]
	mov [boot_storage_fat_reserved_sectors_count], eax

	; fat_fats_count
	mov ebx, .buffer_adr
	movzx eax, byte [ebx + FAT_FATS_COUNT_OFFSET]
	mov [boot_storage_fat_fats_count], eax

	; fat_root_dir_entries_count
	mov ebx, .buffer_adr
	movzx eax, word [ebx + FAT_ROOT_DIR_ENTRIES_COUNT_OFFSET]
	mov [boot_storage_fat_root_dir_entries_count], eax

	; fat_sectors_per_fat
	mov ebx, .buffer_adr
	movzx eax, word [ebx + FAT_SECTORS_PER_FAT_OFFSET]
	mov [boot_storage_fat_sectors_per_fat], eax

	; fat_fat_first_sector <- fat_rserved_sectors_count + partition_first_sector
	mov eax, [boot_storage_fat_reserved_sectors_count]
	add eax, [boot_storage_partition_first_sector]
	mov [boot_storage_fat_fat_first_sector], eax

	; fat_root_dir_first_sector <- fat_fat_first_sector + fat_sectors_per_fat * fat_fats_count
	mov eax, [boot_storage_fat_sectors_per_fat]
	mul dword [boot_storage_fat_fats_count]
	add eax, [boot_storage_fat_fat_first_sector]
	mov [boot_storage_fat_root_dir_first_sector], eax

	mov dword [boot_storage_fat_sectors_per_fat], 10 ; TODO: just a hack, fixme

	; fat_root_dir_sectors_count <- (root_dir_entries_count * BYTES_PER_ENTRY) / bytes_per_sector
	mov eax, [boot_storage_fat_root_dir_entries_count]
	mov ebx, FAT_BYTES_PER_ENTRY
	mul ebx
	div dword [boot_storage_fat_bytes_per_sector]
	mov [boot_storage_fat_root_dir_sectors_count], eax

	; fat_first_data_sector <- fat_root_dir_start_sector + fat_root_dir_sectors_count
	mov eax, [boot_storage_fat_root_dir_first_sector]
	add eax, [boot_storage_fat_root_dir_sectors_count]
	mov [boot_storage_fat_first_data_sector], eax

	; fs_type
	mov ebx, .buffer_adr

	cmp byte [ebx + FAT_FS_ID_OFFSET + 4], `2`
	jne .fs_not_fat12
	mov dword [boot_storage_fs_type], FS_TYPE_FAT12
	jmp .fs_found
.fs_not_fat12:

	cmp byte [ebx + FAT_FS_ID_OFFSET + 4], `6`
	jne .fs_not_fat16
	mov dword [boot_storage_fs_type], FS_TYPE_FAT16
	jmp .fs_found
.fs_not_fat16:

	mov eax, 0
	jmp .end

.fs_found:

	; load fat
	push dword .buffer_adr ; buffer_adr
	push dword .fat_adr ; target_adr

	;push dword [boot_storage_fat_sectors_per_fat] ; sectors_count
	push dword 10 ; TODO: fixme!

	push dword [boot_storage_fat_fat_first_sector] ; first_sector
	call boot_storage_read_sectors_32

	; load root directory
	push dword .buffer_adr ; buffer_adr
	mov eax, [boot_storage_fat_sectors_per_fat]
	mul dword [boot_storage_fat_bytes_per_sector]
	add eax, .fat_adr
	push eax ; target_adr
	push dword [boot_storage_fat_root_dir_sectors_count] ; sectors_count
	push dword [boot_storage_fat_root_dir_first_sector] ; first_sector
	call boot_storage_read_sectors_32

	mov eax, 1

.end:
	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .buffer_adr
%undef .fat_adr
%undef .args_count

;
; Try finding file entry for a given name
; in
;  file_name_adr
;  root_dir_adr
; out
;   eax: address of file entry
%define .args_count 2
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
	cmp eax, dword [boot_storage_fat_root_dir_entries_count]
	jl .loop

	; Gone through all file entries, nothing found
	xor eax, eax
	jmp .end

.found_file:
	mov eax, edi

.end:
	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .root_dir_adr
%undef .file_name_adr
%undef .args_count

;
; Read linked clusters into a given adress
; in
;  first_cluster
;  fat_adr
;  target_adr
;  buffer_adr
%define .args_count 4
%define .first_cluster [ebp + 8]
%define .fat_adr [ebp + 12]
%define .target_adr [ebp + 16]
%define .buffer_adr [ebp + 20]
boot_storage_read_clusters_32:
	push ebp
	mov ebp, esp

	mov eax, .first_cluster

.read_clusters_loop:
	; Calculate sector number (cluster - 2) * sectors_per_cluster + data start offset + parition start offset
	push eax
	sub eax, 2
	mul dword [boot_storage_fat_sectors_per_cluster]
	add eax, [boot_storage_fat_first_data_sector]

	; read cluster
	push dword .buffer_adr ; buffer_adr
	push dword .target_adr ; target_adr
	push dword [boot_storage_fat_sectors_per_cluster] ; sectors_count
	push dword eax ; first_sector
	call boot_storage_read_sectors_32

	; target_adr += bytes_per_sector * sectors_per_cluster
	mov eax, [boot_storage_fat_bytes_per_sector]
	mul dword [boot_storage_fat_sectors_per_cluster]
	add .target_adr, eax

	; Load next cluster number for give fat type
	pop eax ; restore cluster number

	cmp dword [boot_storage_fs_type], FS_TYPE_FAT16
	je .fat16

.fat12:
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
	cmp eax, FAT12_EOF ; range 0x0ff8 - 0x0fff marks the last cluster
	jb .read_clusters_loop
	jmp .end

.fat16:
	mov ebx, 2
	mul ebx
	add eax, .fat_adr

	movzx eax, word [eax]
	cmp eax, FAT16_EOF
	jb .read_clusters_loop

.end:
	mov esp, ebp
	pop ebp
	ret 4 * .args_count
%undef .buffer_adr
%undef .target_adr
%undef .fat_adr
%undef .first_cluster
%undef .args_count