ENTRY(start)
MEMORY
{
    ram : ORIGIN = 0x8000, LENGTH = 0x1000000
}
SECTIONS {
    . = 0x0; 
    .vectortable : {
        
    }

    . = 0x8000;
    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    . = ALIGN(16);
    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
