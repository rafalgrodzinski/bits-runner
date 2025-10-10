OUTPUT_FORMAT(binary)
SECTIONS {
    . = 0x80000000;

    .text : {
        $(.text.start)
        *(.text)
        *(.text*)
    }
    .rodata : {
        *(.rodata)
        *(.rodata*)
    }
    .bss : {
        *(.bss)
        *(.bss*)
    }
    .fake : {
        . = . + SIZEOF(.bss);
    }
    .data : {
        *(.data)
        *(.data*)
        heap = .;
    }
    .shstrtab : {
        *(.shstrtab)
    }
    /DISCARD/ : { * }
}