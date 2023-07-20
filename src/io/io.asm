section .asm

global insb
global insw
global outb
global outw

; 参考
; https://c9x.me/x86/html/file_module_x86_id_139.html
; https://c9x.me/x86/html/file_module_x86_id_222.html

insb:
    push ebp
    mov ebp,esp

    xor eax,eax
    mov edx,[ebp+8]
    in al,dx

    pop ebp
    ret

insw:
    push ebp
    mov ebp,esp

    xor eax,eax
    mov edx,[ebp+8]
    in ax,dx

    pop ebp
    ret

outb:
    push ebp
    mov ebp,esp

    xor eax,eax
    mov edx,[ebp+12]
    mov edx,[ebp+8]
    out dx,al

    pop ebp
    ret

outw:
    push ebp
    mov ebp,esp

    xor eax,eax
    mov edx,[ebp+12]
    mov edx,[ebp+8]
    out dx,ax

    pop ebp
    ret
