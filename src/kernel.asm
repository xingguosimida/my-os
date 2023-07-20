[BITS 32]
global _start
global problem

CODE_SEG equ 0x08
DATA_SEG equ 0x10
extern kernel_main

_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp
    in al, 0x92
    or al, 2
    out 0x92, al
    call kernel_main
    jmp $

problem:
    mov eax, 0
    div eax

times 512-($ - $$) db 0
