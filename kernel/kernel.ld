OUTPUT_FORMAT(binary)
SECTIONS {
    . = 0x80000000;
    .text : {
        *(.text.start)
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