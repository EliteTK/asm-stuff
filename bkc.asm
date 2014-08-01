global _start
section .data
shit    db "Hello bkc."
length  equ $-shit
section .text
_start:
        mov     eax, 4
        mov     ebx, 1
        mov     ecx, shit
        mov     edx, length
        int     0x80
        mov     eax, 1
        mov     ebx, 0
        int     0x80
