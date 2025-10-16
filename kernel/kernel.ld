OUTPUT_FORMAT(binary)
phys = 0x80000000;
SECTIONS {
    
    .text phys : AT(phys) {
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.data .data.*)
        mem.heap = .;
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}