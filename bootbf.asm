org     0x7c00
        jmp start

msg_info:   db "Welcome to Brainfuck OS!", 13, 10
            db "made by chronicle95 in Jan 2018", 13, 10, 13, 10
            db "Type 'e' - enter the program", 13, 10
            db "     'r' - run the program", 13, 10, 0
msg_req:    db 13, 10, "? ", 0
msg_error:  db 13, 10, "Bad command", 0


;; Entry point
start:
        call    clrscr
        mov     ax, msg_info
        call    puts
loop:
        mov     ax, msg_req
        call    puts 
        call    getchar
        cmp     al, 'e'
        jnz     nextcmd0
        ; edit command
        call    bf_edit
        jmp     loop
nextcmd0:
        cmp     al, 'r'
        jnz     nextcmd1
        ; run command
        call    bf_run
        jmp     loop
nextcmd1:
        cmp     al, 13
        jz      loop
        mov     ax, msg_error
        call    puts        
        jmp     loop
        hlt

;; Some I/O functions

getchar:
        call    getch
        call    putch
        ret


getch:
        mov     ah, 0x00        ; read a key
        int     0x16
        ret


putch:
        mov     ah, 0x0e
        int     0x10
        ret


puts:
        mov     si, ax
puts_lp:
        lodsb                   ; AL <- [DS:SI] && SI++
        or      al, al          ; end of string?
        jz      puts_ret
        call    putch
        jmp     puts_lp         ; next char
puts_ret:
        ret


clrscr:
        push    ax
        mov     al, 0x02        ; 80x25
        mov     ah, 0x00        ; set mode and clear screen
        int     0x10
        pop     ax
        ret

;; Brainfuck functions

bf_i:       dw 0xA000
bf_p:       dw 0xB000


bf_fetch_cmd:
        mov     bx, cx
        mov     al, [bx]
        ret


bf_fetch_data:
        mov     bx, dx
        mov     al, [bx]
        ret


bf_edit:
        mov     al, 13          ; go to new line
        call    putch
        mov     al, 10
        call    putch
        mov     bx, [bf_i]      ; initiate char counter
bf_elp:
        call    getchar         ; read key
        cmp     al, 13          ; if it is enter then quit
        jz      bf_ert
        mov     [bx], al        ; otherwise write to memory
        inc     bx              ; and increment the counter
        jmp     bf_elp
bf_ert:
        mov     byte [bx], 0    ; set last byte to 0
        ret


bf_run:
        mov     al, 13          ; go to new line
        call    putch
        mov     al, 10
        call    putch
        mov     cx, word [bf_i] ; instruction pointer
        mov     dx, word [bf_p] ; data pointer
        dec     cx
bf_rlp:
        inc     cx
        call    bf_fetch_cmd
        cmp     al, '+'
        jnz     nextbf0
        call    bf_fetch_data
        inc     al
        mov     [bx], al
        jmp     bf_rlp
nextbf0:
        cmp     al, '-'
        jnz     nextbf1
        call    bf_fetch_data
        dec     al
        mov     [bx], al
        jmp     bf_rlp
nextbf1:        
        cmp     al, '>'
        jnz     nextbf2
        inc     dx
        jmp     bf_rlp
nextbf2:        
        cmp     al, '<'
        jnz     nextbf3
        dec     dx
        jmp     bf_rlp
nextbf3:        
        cmp     al, '.'
        jnz     nextbf4
        call    bf_fetch_data
        call    putch 
        jmp     bf_rlp
nextbf4:        
        cmp     al, ','
        jnz     nextbf5
        mov     bx, dx
        call    getchar
        mov     [bx], al
        jmp     bf_rlp
nextbf5:        
        cmp     al, '['
        jnz     nextbf6
        call    bf_fetch_data
        or      al, al
        jnz     bf_rlp
        push    dx
        mov     dx, 1
lpbgn:
        or      dx, dx
        jz      lpbgn_end
        inc     cx
        call    bf_fetch_cmd
        cmp     al, '['
        jnz     nextlp0
        inc     dx
        jmp     lpbgn
nextlp0:
        cmp     al, ']'
        jnz     lpbgn
        dec     dx
        jmp     lpbgn
lpbgn_end:
        pop     dx
        jmp     bf_rlp
nextbf6:        
        cmp     al, ']'
        jnz     nextbf7
        call    bf_fetch_data
        or      al, al
        jz      bf_rlp
        push    dx
        mov     dx, 1
lpend:
        or      dx, dx
        jz      lpend_end
        dec     cx
        call    bf_fetch_cmd
        cmp     al, '['
        jnz     nextlp1
        dec     dx
        jmp     lpend
nextlp1:
        cmp     al, ']'
        jnz     lpend
        inc     dx
        jmp     lpend
lpend_end:
        pop     dx
        jmp     bf_rlp
nextbf7:
        or      al, al
        jnz     bf_rlp
        ret

times   510 - ($-$$) db 0
dw      0xaa55

