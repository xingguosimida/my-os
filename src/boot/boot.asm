ORG 0x7c00
BITS 16 

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

start:
    jmp 0:step2

step2:
    cli ; Clear Interrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti ; Enables Interrupts

A20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

enter_protected_mode:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or al, 1     
    mov cr0, eax
    
    jmp CODE_SEG:load32


[BITS 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp
    jmp A20
    jmp $

gdt_start:

gdt_null:
    ; Define double word
    dd 0x0
    dd 0x0

; 8 bytes = 64 bits, 刚好是一个表项
; 具体每一个bit的设置可以参考 https://wiki.osdev.org/Global_Descriptor_Table
gdt_code:    
    dw 0xffff ; Segment limit first 0-15 bits,代表4GB
    dw 0      ; Base first 0-15 bits 
    db 0      ; Base 16-23 bits
    db 0x9a   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits
    
gdt_data:      
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x92   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits 
    
gdt_end:
    
    
; 在32位系统中，gdt的描述符的格式为 [0~15] -> 大小，[16~48] -> 偏移量
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ;因为开始索引是0，所以这里需要减1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    dd gdt_start

times 510-($ - $$) db 0

dw 0xAA55
