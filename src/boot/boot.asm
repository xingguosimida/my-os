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


enter_protected_mode:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or al, 1     
    mov cr0, eax
    
    jmp CODE_SEG:load32


[BITS 32]
load32:
    mov eax, 1
    mov ecx, 100
    mov edi, 0x0100000
    call ata_lba_read
    jmp CODE_SEG:0x0100000
    
ata_lba_read:
    pushfd
    and eax, 0x0FFFFFFF
    push eax
    push ebx
    push ecx
    push edx
    push edi
 
    mov ebx, eax         ; Save LBA in EBX
 
    mov edx, 0x01F6      ; Port to send drive and bit 24 - 27 of LBA
    shr eax, 24          ; Get bit 24 - 27 in AL
    or al, 11100000b     ; Set bit 6 in AL for LBA mode
    out dx, al
 
    mov edx, 0x01F2      ; Port to send number of sectors
    mov al, cl           ; Get number of sectors from CL
    out dx, al
 
    mov edx, 0x1F3       ; Port to send bit 0 - 7 of LBA
    mov eax, ebx         ; Get LBA from EBX
    out dx, al
 
    mov edx, 0x1F4       ; Port to send bit 8 - 15 of LBA
    mov eax, ebx         ; Get LBA from EBX
    shr eax, 8           ; Get bit 8 - 15 in AL
    out dx, al
 
    mov edx, 0x1F5       ; Port to send bit 16 - 23 of LBA
    mov eax, ebx         ; Get LBA from EBX
    shr eax, 16          ; Get bit 16 - 23 in AL
    out dx, al
 
    mov edx, 0x1F7       ; Command port
    mov al, 0x20         ; Read with retry.
    out dx, al 

.still_going:
    in al, dx
    test al, 8           ; the sector buffer requires servicing.
    jz .still_going      ; until the sector buffer is ready.
 
    mov eax, 256         ; to read 256 words = 1 sector
    xor bx, bx
    mov bl, cl           ; read CL sectors
    mul bx
    mov ecx, eax         ; ECX is counter for INSW
    mov edx, 0x1F0       ; Data port, in and out
    rep insw             ; in to [EDI]
 
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    popfd
    ret

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
