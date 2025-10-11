OUTPUT_FORMAT(binary)
phys = 0x80000000;
SECTIONS {
    
    .text phys : AT(phys) {
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.data .data.*)
        heap = .;
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}