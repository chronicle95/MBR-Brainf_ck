org     0x7c00
        jmp Lstart

msg_info:   db "Brainf_ck!", 13, 10, 13, 10
            db " * e - edit pgm", 13, 10
            db " * v - view pgm", 13, 10
            db " * x - execute", 13, 10
            db " * r - reset", 13, 10, 0
msg_req:    db 13, 10, "> ", 0
msg_error:  db 13, "?", 0


;; Entry point
Lstart:
        call    Pclrscr
        mov     ax, msg_info
        call    Pputs
Lprompt:
        mov     ax, msg_req
        call    Pputs
        call    Pgetchar
; edit command
        cmp     al, 'e'
        jz      Lbf_edit
; view command
        cmp     al, 'v'
        jz      Lbf_view
; execute command
        cmp     al, 'x'
        jz      Lbf_run
; reset screen command
        cmp     al, 'r'
        jz      Lstart
; pressing enter does nothing
        cmp     al, 13
        jz      Lprompt
; handle unknown command
        mov     ax, msg_error
        call    Pputs
        jmp     Lprompt

;; Some I/O functions

Pgetchar:
        call    Pgetch
        call    Pputch
        ret


Pgetch:
        mov     ah, 0x00        ; read a key
        int     0x16
        ret


Pputch:
        mov     ah, 0x0e
        int     0x10
        ret


Pputs:
        mov     si, ax
puts_lp:
        lodsb                   ; AL <- [DS:SI] && SI++
        or      al, al          ; end of string?
        jz      puts_ret
        call    Pputch
        jmp     puts_lp         ; next char
puts_ret:
        ret


Pclrscr:
        push    ax
        mov     ax, 0x0002      ; set mode 80x25 and clear screen
        int     0x10
        pop     ax
        ret


Pnewline:
        mov     al, 13          ; go to new line
        call    Pputch
        mov     al, 10
        call    Pputch
        ret


;; Brainfuck functions

BF_I equ 0x8000
BF_P equ 0x9000


Pbf_fetch_cmd:
        mov     bx, cx
        mov     al, [bx]
        ret


Pbf_fetch_data:
        mov     bx, dx
        mov     al, [bx]
        ret


Lbf_edit:
        call    Pnewline
        mov     bx, BF_I        ; initiate char counter
bf_elp:
        call    Pgetchar        ; read key
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
        jmp     Lprompt


Lbf_view:
        call    Pnewline
        mov     cx, BF_I
view_loop:
        call    Pbf_fetch_cmd
        or      al, al
        jz      view_end
        call    Pputch
        inc     cx
        jmp     view_loop
view_end:
        jmp     Lprompt


Lbf_run:
        call    Pnewline
        mov     cx, BF_I        ; instruction pointer
        mov     dx, BF_P        ; data pointer
        mov     bp, dx          ; secondary data pointer
        dec     cx
bf_rlp:
        mov     ah, 0x01        ; get key status
        int     0x16
        jz      cont_rlp        ; if no key pressed just continue
        mov     ah, 0x00        ; read key code
        int     0x16
        cmp     al, 27          ; is it escape?
        jnz     cont_rlp        ; if yes, return back to prompt
        jmp     Lprompt
cont_rlp:
        inc     cx
        call    Pbf_fetch_cmd
        cmp     al, '+'         ; INCREMENT
        jnz     nextbf0
        call    Pbf_fetch_data
        inc     al
        mov     [bx], al
        jmp     bf_rlp
nextbf0:
        cmp     al, '-'         ; DECREMENT
        jnz     nextbf1
        call    Pbf_fetch_data
        dec     al
        mov     [bx], al
        jmp     bf_rlp
nextbf1:        
        cmp     al, '>'         ; NEXT CELL
        jnz     nextbf2
        inc     dx
        jmp     bf_rlp
nextbf2:        
        cmp     al, '<'         ; PREVIOUS CELL
        jnz     nextbf3
        dec     dx
        jmp     bf_rlp
nextbf3:        
        cmp     al, '.'         ; OUTPUT CHARACTER
        jnz     nextbf4
        call    Pbf_fetch_data
        call    Pputch
        jmp     bf_rlp
nextbf4:        
        cmp     al, ','         ; INPUT CHARACTER
        jnz     nextbf5
        mov     bx, dx
        call    Pgetchar
        cmp     al, 27          ; handle Escape key to break
        jz      Lprompt
        mov     [bx], al
        jmp     bf_rlp
nextbf5:        
        cmp     al, '['         ; LOOP
        jnz     nextbf6
        call    Pbf_fetch_data
        or      al, al
        jnz     bf_rlp
        push    dx
        mov     dx, 1
lpbgn:
        or      dx, dx
        jz      lpbgn_end
        inc     cx
        call    Pbf_fetch_cmd
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
        cmp     al, ']'         ; END OF LOOP
        jnz     nextbf7
        call    Pbf_fetch_data
        or      al, al
        jz      bf_rlp
        push    dx
        mov     dx, 1
lpend:
        or      dx, dx
        jz      lpend_end
        dec     cx
        call    Pbf_fetch_cmd
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
        cmp     al, '%'         ; SWAP POINTERS
        jnz     nextbf8
        mov     bx, dx          ; use bx as temp
        mov     dx, bp
        mov     bp, bx
        jmp     bf_rlp
nextbf8:
        cmp     al, '^'         ; COPY TO SECONDARY POINTER
        jnz     nextbf9
        mov     bx, dx          ; use bx as temp
        mov     al, [bx]
        mov     [bp], al
        jmp     bf_rlp
nextbf9:
        or      al, al          ; stop the program at 0
        jnz     bf_rlp
        jmp     Lprompt


times   510 - ($-$$) db 0
dw      0xaa55

