OUTPUT_FORMAT(binary)
SECTIONS {
    .text : {
        *(.text.start)
        *(.text)
        *(.text*)
    }
    .rodata : {
        *(.rodata)
    }
    .data : {
        *(.data)
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}