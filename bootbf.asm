org     0x7c00
        jmp Lstart

msg_info:   db "Brainf_ck!", 10, 10
            db "* 0-9 Sel", 10
            db "* E~dit", 10
            db "* R~un", 10
            db "* C~lear", 10, 0
msg_req:    db "> ", 0
msg_error:  db 10, "?", 0


;; Entry point
Lstart:
        mov     ax, 0x0002    ; set mode 80x25 and clear screen
        int     0x10
        mov     ax, msg_info
        call    Pputs
        mov     di, 0         ; use DI as program selector here
Lpromptl:
        call    Pnewline
Lprompt:
        mov     ax, msg_req
        call    Pputs
        call    Pgetchar
; edit command
        cmp     al, 'e'
        jz      Lbf_edit
; run command
        cmp     al, 'r'
        jz      Lbf_run
; clear screen command
        cmp     al, 'c'
        jz      Lstart
; pressing enter does nothing
        cmp     al, 10
        jz      Lprompt
; 0-9 selects and displays a program
        cmp     al, '0'
        jl      unknown_command
        cmp     al, '9'
        jg      unknown_command
        sub     al, '0'
        mov     di, ax
        jmp     Lbf_view
; handle unknown command
unknown_command:
        mov     ax, msg_error
        call    Pputs
        jmp     Lprompt

;; Some I/O functions

Pgetchar:
        mov     ah, 0x00        ; read a key
        int     0x16
        cmp     al, 13          ; yield LF when enter is pressed
        jnz     skip_lf
        mov     al, 10
skip_lf:
        call    Pputchar
        ret


Pputchar:
        mov     ah, 0x0e        ; teletype output command
        cmp     al, 10          ; LF causes CR+LF
        jz      Pnewline
        int     0x10
        ret


Pputs:
        mov     si, ax
puts_lp:
        lodsb                   ; AL <- [DS:SI] && SI++
        or      al, al          ; end of string?
        jz      puts_ret
        call    Pputchar
        jmp     puts_lp         ; next char
puts_ret:
        ret


Pnewline:
        mov     ah, 0x0e        ; print char to teletype
        mov     al, 13          ; print CR
        int     0x10
        mov     al, 10          ; print LF
        int     0x10
        ret


;; Brainfuck functions

BF_PGCNT equ 10
BF_PGSZ  equ 0x400

BF_I equ 0x8000
BF_P equ BF_I+(BF_PGCNT*BF_PGSZ)


Pbf_fetch_cmd:
        mov     bx, cx
        mov     al, [bx]
        ret


Pbf_fetch_data:
        mov     bx, dx
        mov     al, [bx]
        ret


Pbf_calc_pgma:
        push    dx              ; save memory pointer because MUL changes dx
        xor     ah, ah
        mov     cx, BF_PGSZ
        mul     cx              ; multiply pgm index by pgm size
        add     ax, BF_I        ; add program memory offset
        pop     dx
        ret


Lbf_edit:
        call    Pnewline
        mov     ax, di          ; initiate char pointer
        call    Pbf_calc_pgma
        mov     bx, ax
bf_elp:
        call    Pgetchar        ; read key
        cmp     al, 8           ; if backspace then
        jnz     bf_nbs
        dec     bx              ; decrement the counter
        jmp     bf_elp
bf_nbs:
        mov     [bx], al        ; otherwise write to memory
        inc     bx              ; and increment the counter
        cmp     al, 10          ; was it LF?
        jnz     bf_elp          ; no, continue reading
        mov     byte [bx], 0    ; yes, set last byte to 0
        jmp     Lprompt         ; and back to prompt


Lbf_view:
        call    Pnewline
        mov     ax, di          ; initiate char pointer
        call    Pbf_calc_pgma
        call    Pputs
        jmp     Lprompt


Lbf_run:
        call    Pnewline
        mov     ax, di          ; get instruction pointer from pgm number
        mov     dx, BF_P        ; data pointer
        mov     bp, dx          ; secondary data pointer
        mov     di, 0           ; use DI as call depth counter here
bf_subrc:
        call    Pbf_calc_pgma   ; calculate program's instruction pointer
        mov     cx, ax
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
        jz      bf_cmd_inc
        cmp     al, '-'         ; DECREMENT
        jz      bf_cmd_dec
        cmp     al, '>'         ; NEXT CELL
        jz      bf_cmd_next
        cmp     al, '<'         ; PREVIOUS CELL
        jz      bf_cmd_prev
        cmp     al, '.'         ; OUTPUT CHARACTER
        jz      bf_cmd_put
        cmp     al, ','         ; INPUT CHARACTER
        jz      bf_cmd_get
        cmp     al, '['         ; LOOP
        jz      bf_cmd_loop
        cmp     al, ']'         ; END OF LOOP
        jz      bf_cmd_endl
        cmp     al, '%'         ; SWAP POINTERS
        jz      bf_cmd_swap
        cmp     al, '^'         ; COPY TO SECONDARY POINTER
        jz      bf_cmd_copy
        cmp     al, '0'         ; CALL ANOTHER PROGRAM
        jl      bf_cmd_unknown
        cmp     al, '9'
        jg      bf_cmd_unknown
        push    cx              ; save current instruction pointer
        inc     di              ; increment call depth
        jmp     bf_subrc

bf_cmd_unknown:
        or      al, al          ; stop/return the program at 0
        jnz     bf_rlp
        or      di, di          ; do we need to return?
        jz      Lpromptl        ; no, just exit to prompt
        dec     di              ; return from call
        pop     cx
        jmp     bf_rlp
bf_cmd_inc:
        call    Pbf_fetch_data
        inc     al
        mov     [bx], al
        jmp     bf_rlp
bf_cmd_dec:
        call    Pbf_fetch_data
        dec     al
        mov     [bx], al
        jmp     bf_rlp
bf_cmd_next:
        inc     dx
        jmp     bf_rlp
bf_cmd_prev:
        dec     dx
        jmp     bf_rlp
bf_cmd_put:
        call    Pbf_fetch_data
        call    Pputchar
        jmp     bf_rlp
bf_cmd_get:
        mov     bx, dx
        call    Pgetchar
        cmp     al, 27          ; handle Escape key to break
        jz      Lprompt
        mov     [bx], al
        jmp     bf_rlp
bf_cmd_loop:
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
bf_cmd_endl:
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
bf_cmd_swap:
        mov     bx, dx          ; use bx as temp
        mov     dx, bp
        mov     bp, bx
        jmp     bf_rlp
bf_cmd_copy:
        mov     bx, dx          ; use bx as temp
        mov     al, [bx]
        mov     [bp], al
        jmp     bf_rlp


times   510 - ($-$$) db 0
dw      0xaa55

