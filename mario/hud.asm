; AddScore(points) - score = min(score + points, 999,999)
; In : [bp+4]=points (0..65535)   Out: score   Changes: none
AddScore:
        push bp
        mov  bp,sp
        push ax
        mov  ax,[bp+4]
        add  [score],ax
        adc  word [score+2],0           ; 32-bit add with carry
        cmp  word [score+2],MAX_SCORE_HI
        jb   .ok
        ja   .clamp
        cmp  word [score],MAX_SCORE_LO
        jbe  .ok
.clamp: mov  word [score],MAX_SCORE_LO
        mov  word [score+2],MAX_SCORE_HI
.ok:    pop  ax
        pop  bp
        ret  2

; AddLife - lives + 1, never above 99.   In/Out: lives   Changes: none
AddLife:
        cmp  word [lives],MAX_LIVES
        jae  .done
        inc  word [lives]
.done:  ret

; AddCoin - coins + 1; at 100 coins: +1 life and coins back to 0
AddCoin:
        inc  word [coins]
        cmp  word [coins],100
        jb   .done
        mov  word [coins],0
        call AddLife
.done:  ret

; DrawNumber(x, y, low, high, digits, colour, scale)
; Prints the 32-bit value high:low as a zero-padded decimal number.  Digits are
; produced by repeated division by 10, remainders pushed on the stack and
; popped in reverse order (most significant first).
; In : [bp+16]=x [bp+14]=y [bp+12]=low [bp+10]=high [bp+8]=digits
;      [bp+6]=colour [bp+4]=scale          Out: none   Changes: none
DrawNumber:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        mov  si,[bp+12]                 ; low word
        mov  bx,[bp+10]                 ; high word
        mov  cx,[bp+8]                  ; number of digits
        mov  di,10
.div:   mov  ax,bx
        xor  dx,dx
        div  di                         ; high / 10, remainder in DX
        mov  bx,ax
        mov  ax,si
        div  di                         ; (rem:low) / 10 -> DX = digit
        mov  si,ax
        push dx                         ; remember the digit
        loop .div
        mov  cx,[bp+8]
        mov  si,[bp+16]                 ; x
        mov  di,[bp+4]
        shl  di,2                       ; advance per digit
.print: pop  ax                         ; most significant digit first
        add  al,'0'
        xor  ah,ah
        push si
        push word [bp+14]
        push ax
        push word [bp+6]
        push word [bp+4]
        call DrawChar
        add  si,di
        loop .print
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  14

; DrawHeart(x, y, filled) - 16 x 12 heart icon (8x6 bitmap at scale 2)
; In : [bp+8]=x [bp+6]=y [bp+4]=filled (1 = red, 0 = grey outline colour)
; Out: none   Changes: none
DrawHeart:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        mov  dx,C_DGRAY
        cmp  word [bp+4],0
        je   .col
        mov  dx,C_RED
.col:   xor  si,si                      ; row 0..5
.row:   mov  al,[heart_bits+si]
        mov  cx,8
        mov  di,[bp+8]
.px:    test al,80h
        jz   .blank
        push di
        mov  bx,si
        shl  bx,1
        add  bx,[bp+6]
        push bx
        push 2
        push 2
        push dx
        call FillRect
.blank: shl  al,1
        add  di,2
        loop .px
        inc  si
        cmp  si,6
        jb   .row
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  6

; DrawHUD - top 16-pixel strip: SCORE COINS WORLD TIME LIVES and two hearts
DrawHUD:
        push ax
        push 0
        push 0
        push SCREEN_W
        push 16
        push C_BLACK
        call FillRect
        ; labels, scale 1, yellow
        push 4
        push 1
        push str_score
        push C_YELLOW
        push 1
        call DrawString
        push 64
        push 1
        push str_coins
        push C_YELLOW
        push 1
        call DrawString
        push 104
        push 1
        push str_world
        push C_YELLOW
        push 1
        call DrawString
        push 144
        push 1
        push str_time
        push C_YELLOW
        push 1
        call DrawString
        push 184
        push 1
        push str_lives
        push C_YELLOW
        push 1
        call DrawString
        ; values, scale 2, white
        push 4
        push 6
        push word [score]
        push word [score+2]
        push 6
        push C_WHITE
        push 2
        call DrawNumber
        push 64
        push 6
        push str_x
        push C_WHITE
        push 2
        call DrawString
        push 72
        push 6
        push word [coins]
        push 0
        push 2
        push C_WHITE
        push 2
        call DrawNumber
        push 104
        push 6
        push str_world_val
        push C_WHITE
        push 2
        call DrawString
        push 144
        push 6
        push word [time_left]
        push 0
        push 3
        push C_WHITE
        push 2
        call DrawNumber
        push 184
        push 6
        push str_x
        push C_WHITE
        push 2
        call DrawString
        push 192
        push 6
        push word [lives]
        push 0
        push 2
        push C_WHITE
        push 2
        call DrawNumber
        ; health hearts: first always filled, second only for Super Mario
        push 240
        push 2
        push 1
        call DrawHeart
        mov ax, ax
        cmp  word [hp],2
        jne  .h2
        mov  ax,1
.h2:    push 262
        push 2
        push ax
        call DrawHeart
        pop  ax
        ret

;data
score           dw 0, 0                 ; 32-bit: low word, high word
coins           dw 0
lives           dw START_LIVES
str_score       db 'SCORE',0
str_coins       db 'COINS',0
str_world       db 'WORLD',0
str_time        db 'TIME',0
str_lives       db 'LIVES',0
str_x           db 'X',0
str_world_val   db '1-1',0