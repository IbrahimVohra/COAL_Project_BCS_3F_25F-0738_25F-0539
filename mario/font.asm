; DrawChar(x, y, char, colour, scale) - one glyph, each pixel scale x scale
; In : [bp+12]=x [bp+10]=y [bp+8]=char [bp+6]=colour [bp+4]=scale
; Out: none   Changes: none.  Unknown characters (space) draw nothing.
DrawChar:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        mov  ax,[bp+8]
        cmp  al,'a'
        jb   .caps
        cmp  al,'z'
        ja   .caps
        and  al,0DFh                    ; lower case -> upper case

.caps:  cmp  al,'-'
        jne  .c1
        mov  al,36
        jmp  .have

.c1:    cmp  al,':'
        jne  .c2
        mov  al,37
        jmp  .have

.c2:    cmp  al,'!'
        jne  .c3
        mov  al,38
        jmp  .have

.c3:    cmp  al,'.'
        jne  .c4
        mov  al,39
        jmp  .have

.c4:    cmp  al,'0'
        jae  .tr1
        jmp  .done

.tr1:
        cmp  al,'9'
        ja   .letter
        sub  al,'0'
        jmp  .have
.letter:
        cmp  al,'A'
        jae  .tr2
        jmp  .done
.tr2:
        cmp  al,'Z'
        jbe  .tr3
        jmp  .done
.tr3:
        sub  al,'A'-10

.have:  mov ah,0
        mov  si,ax
        shl  si,2
        add  si,ax                      ; si = index*5
        add  si,font_data
        mov  bx,[bp+10]                 ; current y
        mov  dx,5                       ; rows

.row:   mov  al,[si]
        inc  si
        mov  cx,3
        mov  di,[bp+12]                 ; current x

.col:   test al,4
        jz   .blank
        push di
        push bx
        push word [bp+4]
        push word [bp+4]
        push word [bp+6]
        call FillRect

.blank: shl  al,1
        add  di,[bp+4]
        loop .col
        add  bx,[bp+4]
        dec  dx
        jnz  .row

.done:  pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  10

; DrawString(x, y, address, colour, scale) - zero-terminated string
; In : [bp+12]=x [bp+10]=y [bp+8]=address [bp+6]=colour [bp+4]=scale
DrawString:
        push bp
        mov  bp,sp
        push ax
        push bx
        push si
        push di
        mov  si,[bp+8]
        mov  bx,[bp+12]
        mov  di,[bp+4]
        shl  di,2                       ; advance = 4 * scale

.next:  lodsb
        test al,al
        jz   .done
        xor  ah,ah
        push bx
        push word [bp+10]
        push ax
        push word [bp+6]
        push word [bp+4]
        call DrawChar
        add  bx,di
        jmp  .next

.done:  pop  di
        pop  si
        pop  bx
        pop  ax
        pop  bp
        ret  10

; StrLen(address) - length of a zero-terminated string
; In : [bp+4]=address   Out: AX=length   Changes: AX
StrLen:
        push bp
        mov  bp,sp
        push si
        mov  si,[bp+4]
        xor  ax,ax

.next:  cmp  byte [si],0
        je   .done
        inc  si
        inc  ax
        jmp  .next

.done:  pop  si
        pop  bp
        ret  2

; DrawCentered(y, address, colour, scale) - string centred horizontally
; In : [bp+10]=y [bp+8]=address [bp+6]=colour [bp+4]=scale
DrawCentered:
        push bp
        mov  bp,sp
        push ax
        push bx
        push dx
        push word [bp+8]
        call StrLen
        mov  bx,[bp+4]
        shl  bx,2
        mul  bx                         ; ax = width in pixels
        mov  bx,SCREEN_W
        sub  bx,ax
        shr  bx,1                       ; x = (320 - width) / 2
        push bx
        push word [bp+10]
        push word [bp+8]
        push word [bp+6]
        push word [bp+4]
        call DrawString
        pop  dx
        pop  bx
        pop  ax
        pop  bp
        ret  8

;data
font_data:
        db 111b,101b,101b,101b,111b     ; 0
        db 010b,110b,010b,010b,111b     ; 1
        db 111b,001b,111b,100b,111b     ; 2
        db 111b,001b,111b,001b,111b     ; 3
        db 101b,101b,111b,001b,001b     ; 4
        db 111b,100b,111b,001b,111b     ; 5
        db 111b,100b,111b,101b,111b     ; 6
        db 111b,001b,001b,001b,001b     ; 7
        db 111b,101b,111b,101b,111b     ; 8
        db 111b,101b,111b,001b,111b     ; 9
        db 010b,101b,111b,101b,101b     ; A
        db 110b,101b,110b,101b,110b     ; B
        db 011b,100b,100b,100b,011b     ; C
        db 110b,101b,101b,101b,110b     ; D
        db 111b,100b,110b,100b,111b     ; E
        db 111b,100b,110b,100b,100b     ; F
        db 011b,100b,101b,101b,011b     ; G
        db 101b,101b,111b,101b,101b     ; H
        db 111b,010b,010b,010b,111b     ; I
        db 001b,001b,001b,101b,010b     ; J
        db 101b,101b,110b,101b,101b     ; K
        db 100b,100b,100b,100b,111b     ; L
        db 101b,111b,111b,101b,101b     ; M
        db 110b,101b,101b,101b,101b     ; N
        db 010b,101b,101b,101b,010b     ; O
        db 110b,101b,110b,100b,100b     ; P
        db 010b,101b,101b,111b,011b     ; Q
        db 110b,101b,110b,101b,101b     ; R
        db 011b,100b,010b,001b,110b     ; S
        db 111b,010b,010b,010b,010b     ; T
        db 101b,101b,101b,101b,111b     ; U
        db 101b,101b,101b,101b,010b     ; V
        db 101b,101b,111b,111b,101b     ; W
        db 101b,101b,010b,101b,101b     ; X
        db 101b,101b,010b,010b,010b     ; Y
        db 111b,001b,010b,100b,111b     ; Z
        db 000b,000b,111b,000b,000b     ; -
        db 000b,010b,000b,010b,000b     ; :
        db 010b,010b,010b,000b,010b     ; !
        db 000b,000b,000b,000b,010b     ; .

heart_bits      db 01100110b,11111111b,11111111b,01111110b,00111100b,00011000b
