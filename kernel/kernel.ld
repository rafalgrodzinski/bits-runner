OUTPUT_FORMAT(binary)
SECTIONS {
    . = 0x80000000;
    .text : {
        *(.text.start)
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.data .data.*)
        . = ALIGN(0x1000);
        Memory.heap = .;
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}