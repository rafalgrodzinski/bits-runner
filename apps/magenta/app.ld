OUTPUT_FORMAT(binary)
SECTIONS {
    . = 0x00400000;
    .text : {
        *(.text.start)
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.data .data.*)
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}