global  _start
section .text
_start:
        pop     eax             ; get argc
        cmp     eax, 1          ; cmp argc, 0
        je      exit            ; if argc = 0, exit
        dec     eax             ; skip argv[0]
        add     esp, 4          ; skip argv[0]
printloop:
        pop     ecx             ; get next char *
        push    eax             ; store amount to print on stack
        push    ecx             ; put char * on stack for strlen
        call    strlen          ; call strlen
        pop     edx             ; pop strlen into edx
        mov     ebx, 1          ; stdout
        mov     eax, 4          ; sys_write
        int     0x80            ; syscall
        pop     eax             ; get the argcount back
        dec     eax             ; argc--
        cmp     eax, 0          ; if argc == 0
        je      endprint        ; exit
        push    eax             ; store eax temporarily
        mov     eax, 4          ; sys_write
        mov     ecx, SPACE      ; space
        mov     edx, 1          ; stdout
        int     0x80            ; syscall
        pop     eax             ; get eax back
        jmp     printloop       ; loop
endprint:
        mov     eax, 4          ; sys_write
        mov     ebx, 1
        mov     ecx, LF         ; newline
        mov     edx, 1          ; length 1
        int     0x80            ; syscall
        jmp     exit            ; exit

strlen:
        pop     edx             ; return address
        pop     ebx             ; char *
        xor     eax, eax        ; zero offset
len_loop:
        cmp     byte [ebx+eax], 0       ; if the char is null
        je      len_end         ; end loop
        inc     eax             ; increment offset
        jmp     len_loop        ; loop
len_end:
        push    eax             ; push onto stack
        push    edx             ; return address
        ret                     ; return

exit:
        mov     eax, 1          ; sys_exit
        xor     ebx, ebx        ; return 0
        int     0x80            ; syscall

section .data
LF:     db 0xA                  ; newline
SPACE:  db ' '                  ; space
