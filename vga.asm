BITS 16

org     0x7C00

boot_loader:
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

        call main

sector_pad:
        times ((0x200 - 2) - ($ - $$)) db 0
        dw 0xAA55


main:
        push    bp
        mov     bp, sp
        sub     sp, 4
        pushaw

        xor     ah, ah          ; Set video mode
        mov     al, 0x13        ; VGA 320 x 200, 256 colour
        int     0x10            ; Video Services

        mov     word [bp-2], 0  ; x
        mov     word [bp-4], 0  ; y

        mov     cx, 256         ; Counter
draw_loop:
        mov     ax, [bp-2]      ; x
        mov     bx, 4           ; 4
        mul     bx              ; x * 4
        push    ax              ; push x arg
        mov     ax, [bp-4]      ; y
        mul     bx              ; y * 4
        push    ax              ; push y arg
        push    4               ; push width arg
        push    4               ; push height arg
        mov     dx, 256         ; cx start value
        sub     dx, cx          ; Get the colour value
        push    dx              ; push colour arg
        call    fill_rect       ; fill rectangle
        add     sp, 10          ; pop args
        inc     word [bp-2]     ; Increment pos_x
        cmp     word [bp-2], 16 ; Compare pos_x vs max_x
        jb      no_new_row      ; If pos_x is still less than max_x, go to new_row
        mov     word [bp-2], 0  ; zero pos_x
        inc     word [bp-4]     ; increment pos_y
no_new_row:
        dec     cx              ; decrement colour-value
        cmp     cx, 0           ; compare colour-value against 0
        jne     draw_loop       ; jump back if above 0

        popaw
        add     sp, 4
        pop     bp
        ret

put_pixel:      ; x, y, colour
        push    bp
        mov     bp, sp
        pushaw

        mov     ah, 0x0C        ; Write graphics pixel
        mov     al, [bp+4]      ; Color (4 = push bp and push retp)
        mov     bh, 0           ; Page number
        mov     cx, [bp+8]      ; x_val
        mov     dx, [bp+6]      ; y_val
        int     0x10            ; Video Services

        popaw
        pop     bp
        ret
        
get_min:        ;(min), a, b
        push    bp
        mov     bp, sp

        cmp     word [bp-6], word [bp-8]
        cmovle  word [bp-4], word [bp-6]
        cmovg   word [bp-4], word [bp-8]

        pop     bp
        ret
        
get_max:        ; (max), a, b
        push    bp
        mov     bp, sp

        cmp     word [bp-6], word [bp-8]
        cmovge  word [bp-4], word [bp-6]
        cmovl   word [bp-4], word [bp-8]

        pop     bp
        ret

fill_rect:      ; x, y, width, height, colour
        push    bp
        mov     bp, sp
        pushaw

        mov     ax, [bp+8]      ; width
        mov     dx, [bp+6]      ; height
        mul     dx              ; width * height
        mov     dx, ax          ; move result to dx
        xor     ax, ax          ; x_offset = 0
        xor     bx, bx          ; y_offset = 0
        xor     cx, cx          ; total pixels drawn
fill_rect_loop:
        push    cx              ; store cx
        mov     cx, [bp+12]     ; x
        add     cx, ax          ; x + x_offset
        push    cx              ; push x + offset
        mov     cx, [bp+10]     ; y
        add     cx, bx          ; y + y_offset
        push    cx              ; push y + offset
        push    word [bp+4]     ; colour
        call    put_pixel
        add     sp, 6           ; pop args
        pop     cx              ; restore cx
        inc     ax              ; increment x_offset
        inc     cx              ; increment total pixels
        cmp     ax, [bp+8]      ; figure out if the x_offset is too big
        jb      fill_rect_c_row ; continue if not
        xor     ax, ax          ; if it has, zero x_offset
        inc     bx              ; increment y_offset instead
fill_rect_c_row:
        cmp     cx, dx          ; cmp pixels drawn, total pixels needed
        jb      fill_rect_loop  ; if we've drawn all the pixels, go back

        popaw
        pop     bp
        ret

fill_trig:      ; x1, y1, x2, y2, x3, y3, colour
        push    bp
        mov     bp, sp
        sub     sp, 8   ; minx, miny, maxx, maxy
        pushaw
        
        ;;;; CALCULATING AABB ;;;;
        
        mov     word [bp-2], word [bp+4]        ; initialise minx
        mov     word [bp-4], word [bp+4]        ; initialise miny
        mov     word [bp-6], word [bp+6]        ; initialise maxx
        mov     word [bp-8], word [bp+6]        ; initialise maxy

        ; minx
        push    word [bp-2]                     ; minx
        push    word [bp+8]                     ; x2
        sub     sp, 2                           ; retval
        call    get_min                         ; min(minx, x2)
        pop     word [bp-2]                     ; store next minx
        add     sp, 4                           ; clean stack
        push    word [bp-2]                     ; minx
        push    word [bp+12]                    ; x3
        sub     sp, 2                           ; retval
        call    get_min                         ; min(minx, x3)
        pop     word [bp-2]                     ; store final minx
        add     sp, 4                           ; clean stack
        
        ; miny
        push    word [bp-4]                     ; miny
        push    word [bp+10]                    ; y2
        sub     sp, 2                           ; retval
        call    get_min                         ; min(miny, y2)
        pop     word [bp-4]                     ; store next miny
        add     sp, 4                           ; clean stack
        push    word [bp-4]                     ; miny
        push    word [bp+14]                    ; y3
        sub     sp, 2                           ; retval
        call    get_min                         ; min(miny, y3)
        pop     word [bp-4]                     ; store final miny
        add     sp, 4                           ; clean stack

        ; maxx
        push    word [bp-6]                     ; maxx
        push    word [bp+8]                     ; x2
        sub     sp, 2                           ; retval
        call    get_max                         ; max(maxx, x2)
        pop     word [bp-6]                     ; store next maxx
        add     sp, 4                           ; clean stack
        push    word [bp-6]                     ; maxx
        push    word [bp+12]                    ; x3
        sub     sp, 2                           ; retval
        call    get_max                         ; max(maxx, x3)
        pop     word [bp-6]                     ; store final maxx
        add     sp, 4                           ; clean stack
        
        ; maxy
        push    word [bp-8]                     ; maxy
        push    word [bp+10]                    ; y2
        sub     sp, 2                           ; retval
        call    get_max                         ; max(maxy, y2)
        pop     word [bp-8]                     ; store next maxy
        add     sp, 4                           ; clean stack
        push    word [bp-8]                     ; maxy
        push    word [bp+14]                    ; y3
        sub     sp, 2                           ; retval
        call    get_max                         ; max(maxy, y3)
        pop     word [bp-8]                     ; store final maxy
        add     sp, 4                           ; clean stack

        ; now that we have our AABB, prepare iterator.
        mov     ax, [bp-2]                      ; x initial
        mov     bx, [bp-4]                      ; y initial
        mov     cx, [bp-6]                      ; x max
        mov     dx, [bp-8]                      ; y max
draw_trig_loop:
        

        popaw
        add     sp, 8
        pop     bp
        ret

sector_pad_2:
        times (0x2000 - ($ - $$)) db 0