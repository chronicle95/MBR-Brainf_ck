org     0x7c00
        jmp Lstart

msg_info:   db "Brainfuck!", 13, 10
            db "Type 'e' - enter the program", 13, 10
            db "     'r' - run the program", 13, 10, 0
msg_req:    db 13, 10, "? ", 0
msg_error:  db 13, 10, "Bad command", 0


;; Entry point
Lstart:
        call    Lclrscr
        mov     ax, msg_info
        call    Lputs
loop:
        mov     ax, msg_req
        call    Lputs
        call    Lgetchar
        cmp     al, 'e'
        jnz     nextcmd0
        ; edit command
        call    Lbf_edit
        jmp     loop
nextcmd0:
        cmp     al, 'r'
        jnz     nextcmd1
        ; run command
        call    Lbf_run
        jmp     loop
nextcmd1:
        cmp     al, 13
        jz      loop
        mov     ax, msg_error
        call    Lputs
        jmp     loop
        hlt

;; Some I/O functions

Lgetchar:
        call    Lgetch
        call    Lputch
        ret


Lgetch:
        mov     ah, 0x00        ; read a key
        int     0x16
        ret


Lputch:
        mov     ah, 0x0e
        int     0x10
        ret


Lputs:
        mov     si, ax
puts_lp:
        lodsb                   ; AL <- [DS:SI] && SI++
        or      al, al          ; end of string?
        jz      puts_ret
        call    Lputch
        jmp     puts_lp         ; next char
puts_ret:
        ret


Lclrscr:
        push    ax
        mov     al, 0x02        ; 80x25
        mov     ah, 0x00        ; set mode and clear screen
        int     0x10
        pop     ax
        ret

;; Brainfuck functions

bf_i:       dw 0xA000
bf_p:       dw 0xB000


Lbf_fetch_cmd:
        mov     bx, cx
        mov     al, [bx]
        ret


Lbf_fetch_data:
        mov     bx, dx
        mov     al, [bx]
        ret


Lbf_edit:
        mov     al, 13          ; go to new line
        call    Lputch
        mov     al, 10
        call    Lputch
        mov     bx, [bf_i]      ; initiate char counter
bf_elp:
        call    Lgetchar         ; read key
        cmp     al, 13          ; if it is enter then quit
        jz      bf_ert
        cmp     al, 8           ; if backspace then
        jnz     bf_nbs
        dec     bx              ; decrement the counter
        jmp     bf_elp
bf_nbs:
        mov     [bx], al        ; otherwise write to memory
        inc     bx              ; and increment the counter
        jmp     bf_elp
bf_ert:
        mov     byte [bx], 0    ; set last byte to 0
        ret


Lbf_run:
        mov     al, 13          ; go to new line
        call    Lputch
        mov     al, 10
        call    Lputch
        mov     cx, word [bf_i] ; instruction pointer
        mov     dx, word [bf_p] ; data pointer
        dec     cx
bf_rlp:
        inc     cx
        call    Lbf_fetch_cmd
        cmp     al, '+'
        jnz     nextbf0
        call    Lbf_fetch_data
        inc     al
        mov     [bx], al
        jmp     bf_rlp
nextbf0:
        cmp     al, '-'
        jnz     nextbf1
        call    Lbf_fetch_data
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
        call    Lbf_fetch_data
        call    Lputch
        jmp     bf_rlp
nextbf4:        
        cmp     al, ','
        jnz     nextbf5
        mov     bx, dx
        call    Lgetchar
        mov     [bx], al
        jmp     bf_rlp
nextbf5:        
        cmp     al, '['
        jnz     nextbf6
        call    Lbf_fetch_data
        or      al, al
        jnz     bf_rlp
        push    dx
        mov     dx, 1
lpbgn:
        or      dx, dx
        jz      lpbgn_end
        inc     cx
        call    Lbf_fetch_cmd
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
        call    Lbf_fetch_data
        or      al, al
        jz      bf_rlp
        push    dx
        mov     dx, 1
lpend:
        or      dx, dx
        jz      lpend_end
        dec     cx
        call    Lbf_fetch_cmd
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

