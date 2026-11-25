; SetMode13 - switch to VGA 320x200x256.   In: none  Out: none  Changes: none
SetMode13:
        push ax
        mov  ax,0013h
        int  10h
        pop  ax
        ret
; SetTextMode - back to 80x25 text.   In: none  Out: none  Changes: none
SetTextMode:
        push ax
        mov  ax,0003h
        int  10h
        pop  ax
        ret

; InitPalette - program DAC registers 0..15 from palette_table via INT 10h
; In: none  Out: none  Changes: none
InitPalette:
        push ax
        push bx
        push cx
        push dx
        push si
        mov  si,palette_table
        xor  bx,bx
.next:
        mov  dh,[si]                    ; red
        mov  ch,[si+1]                  ; green
        mov  cl,[si+2]                  ; blue
        mov  ax,1010h                   ; set one DAC register
        push bx
        int  10h
        pop  bx
        add  si,3
        inc  bx
        cmp  bx,16
        jb   .next
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

PutPixel:
        push bp
        mov  bp,sp
        push ax
        push bx
        push di
        push es
        mov  ax,[bp+6]                  ; y
        cmp  ax,SCREEN_H
        jae  .done                      ; unsigned: also rejects negatives
        mov  bx,[bp+8]                  ; x
        cmp  bx,SCREEN_W
        jae  .done
        mov  di,ax
        shl  ax,8                       ; y*256
        shl  di,6                       ; y*64
        add  di,ax
        add  di,bx
        mov  es,[draw_seg]
        mov  al,[bp+4]
        mov  [es:di],al
.done:
        pop  es
        pop  di
        pop  bx
        pop  ax
        pop  bp
        ret  6

; FillRect(x, y, w, h, colour) - filled rectangle, clipped to the screen
; In : [bp+12]=x [bp+10]=y [bp+8]=w [bp+6]=h [bp+4]=colour
; Out: none   Changes: none
FillRect:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es
        mov  ax,[bp+12]                 ; x1
        mov  bx,[bp+10]                 ; y1
        mov  cx,ax
        add  cx,[bp+8]                  ; x2 (exclusive)
        mov  dx,bx
        add  dx,[bp+6]                  ; y2 (exclusive)
        test ax,ax
        jns  .x1ok
        xor  ax,ax

.x1ok:  test bx,bx
        jns  .y1ok
        xor  bx,bx

.y1ok:  cmp  cx,SCREEN_W
        jle  .x2ok
        mov  cx,SCREEN_W

.x2ok:  cmp  dx,SCREEN_H
        jle  .y2ok
        mov  dx,SCREEN_H

.y2ok:  cmp  ax,cx
        jge  .done                      ; nothing visible
        cmp  bx,dx
        jge  .done
        sub  cx,ax
        mov  si,cx                      ; si = visible width
        sub  dx,bx                      ; dx = visible rows
        mov  di,bx
        shl  bx,8
        shl  di,6
        add  di,bx
        add  di,ax                      ; di = y*320 + x
        mov  es,[draw_seg]
        mov  al,[bp+4]
        mov  ah,al
        cld

.row:   mov  cx,si
        push di
        rep  stosb
        pop  di
        add  di,SCREEN_W
        dec  dx
        jnz  .row

.done:  pop  es
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  10

; ColourTest - draw 16 colour swatches along the top (Module 2 test screen)
; In: none  Out: none  Changes: none
ColourTest:
        push ax
        push bx
        push cx
        push dx
        xor  bx,bx

.next:  mov  ax,bx
        mov  cx,20
        mul  cx                         ; ax = i*20
        push ax
        push 0
        push 20
        push 14
        push bx
        call FillRect
        inc  bx
        cmp  bx,16
        jb   .next
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

; palette (6-bit R,G,B) for colour indices 0..15, see consts.inc C_*
palette_table:
        db  0, 0, 0                     ; 0 black / transparent
        db 23,37,63                     ; 1 sky
        db 46,20, 6                     ; 2 brick
        db 63,48,28                     ; 3 skin
        db 58, 6, 6                     ; 4 red
        db  8,16,56                     ; 5 blue
        db 30,16, 4                     ; 6 brown
        db  6,40,10                     ; 7 pipe green
        db 28,58,30                     ; 8 light green
        db 63,58, 6                     ; 9 yellow
        db 60,36, 4                     ; 10 orange
        db 63,63,63                     ; 11 white
        db 36,36,36                     ; 12 gray
        db  4,34, 8                     ; 13 dark green
        db 50,32,14                     ; 14 tan
        db 14,14,14                     ; 15 dark gray
