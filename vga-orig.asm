BITS 16

org     0x7C00

boot_stage_1:
        xor     ah, ah          ; Reset Disk Drives
        xor     dl, dl          ; drive A:
        int     0x13            ; LLD Services
        
        mov     ah, 0x02        ; Read Sectors
        mov     al, 0x10        ; Amount
        xor     dl, dl          ; Drive number
        xor     ch, ch          ; Cylinder number
        xor     dh, dh          ; Head number
        mov     cl, 2           ; Start sector
        mov     bx, main        ; Memory location
        int     0x13            ; LLD Services
        
        jmp main
        
sector_pad:
        times ((0x200 - 2) - ($ - $$)) db 0
        dw 0xAA55


main:
        xor     ah, ah          ; Set video mode
        mov     al, 0x13        ; VGA 320 x 200, 256 colour
        int     0x10            ; Video Services
        
        xor     ax, ax          ; pos_x
        xor     bx, bx          ; pos_y
        
        mov     cx, 256         ; Counter
draw_loop:
        push    ax              ; pos_x
        push    bx              ; pos_y
        mov     dx, 256         ; cx start value
        sub     dx, cx          ; Get the colour value
        push    dx              ; Colour
        call    draw_pixel_xy   ; Draw pixel
        inc     ax              ; Increment pos_x
        cmp     ax, 16          ; Compare pos_x vs max_x
        jb      new_row         ; If pos_x is still less than max_x, go to new_row
        xor     ax, ax          ; else, zero ax
        inc     bx              ; increment bx
new_row:
        dec     cx              ; decrement colour-value
        cmp     cx, 0           ; compare colour-value against 0
        jg      draw_loop       ; jump back if above 0
        
        ret

draw_pixel_xy:
        push    bp              ; store base pointer
        mov     bp, sp          ; base pointer = stack pointer
        
;        pushaw

        push    ax              ; store ax
        push    bx              ; store bx
        push    cx              ; store cx
        push    dx              ; store dx
        
        mov     ah, 0x0C        ; Write graphics pixel
        mov     al, [bp+4]      ; Color (4 = push bp and push retp)
        mov     bh, 0           ; Page number
        mov     cx, [bp+8]      ; x_val
        mov     dx, [bp+6]      ; y_val
        int     0x10            ; Video Services

;        popaw

        pop     dx              ; restore dx
        pop     cx              ; restore cx
        pop     bx              ; restore bx
        pop     ax              ; restore ax
        
        pop     bp              ; restore base pointer
        ret                     ; return
        
sector_pad_2:
        times (0x2000 - ($ - $$)) db 0