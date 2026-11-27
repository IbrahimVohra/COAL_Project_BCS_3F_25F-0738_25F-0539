; SolidAt(px, py) - is the tile at this pixel solid (codes 1..10)?
; In : [bp+6]=px [bp+4]=py     Out: AX=1 solid, 0 not     Changes: AX only

SolidAt:
        push bp
        mov  bp,sp
        push word [bp+6]
        push word [bp+4]
        call GetTile
        cmp  ax,T_GROUND
        jb   .no
        cmp  ax,T_STAIR
        ja   .no
        mov  ax,1
        jmp  .out
.no:    xor  ax,ax
.out:   pop  bp
        ret  4


; HeroColumnSolid(px) - any solid tile at column px beside Mario's body?
; Samples three heights: top, middle, feet-1 (spacing <= 16 so no tile row
; can be skipped).   In: [bp+4]=px   Out: AX=1/0   Changes: AX only

HeroColumnSolid:
        push bp
        mov  bp,sp
        push bx
        push cx
        mov  bx,[mario_y]
        sub  bx,[mario_h]               ; top
        push word [bp+4]
        push bx
        call SolidAt
        test ax,ax
        jnz  .out
        mov  cx,[mario_h]
        shr  cx,1
        add  cx,bx                      ; middle
        push word [bp+4]
        push cx
        call SolidAt
        test ax,ax
        jnz  .out
        mov  cx,[mario_y]
        dec  cx                         ; last row of the feet
        push word [bp+4]
        push cx
        call SolidAt
.out:   pop  cx
        pop  bx
        pop  bp
        ret  2

; MoveMarioX - apply mario_vx, keep inside the level, stop at walls
MoveMarioX:
        push ax
        push mario_xf
        push word [mario_vx]
        call AddFixed
        cmp  word [mario_x],0
        jge  .rightend
        mov  word [mario_x],0           ; level left end
        mov  word [mario_xf],0
        mov  word [mario_vx],0
.rightend:
        cmp  word [mario_x],LEVEL_PX-16
        jle  .walls
        mov  word [mario_x],LEVEL_PX-16 ; level right end
        mov  word [mario_xf],0
        mov  word [mario_vx],0
.walls: mov  ax,[mario_vx]
        test ax,ax
        jnz  .tr1
        jmp  .end
.tr1:
        js   .left
        mov  ax,[mario_x]               ; moving right: test right edge x+13
        add  ax,13
        push ax
        call HeroColumnSolid
        test ax,ax
        jnz  .tr2
        jmp  .end
.tr2:
        mov  ax,[mario_x]
        add  ax,13
        and  ax,0FFF0h                  ; left side of the wall tile
        sub  ax,14                      ; right edge (x+14) touches it
        mov  [mario_x],ax
        mov  word [mario_xf],0
        mov  word [mario_vx],0
        jmp  .end
.left:  mov  ax,[mario_x]               ; moving left: test left edge x+2
        add  ax,2
        push ax
        call HeroColumnSolid
        test ax,ax
        jz   .end
        mov  ax,[mario_x]
        add  ax,2
        and  ax,0FFF0h
        add  ax,14                      ; tile right edge (16) minus 2
        mov  [mario_x],ax
        mov  word [mario_xf],0
        mov  word [mario_vx],0
.end:   pop  ax
        ret

; MoveMarioY - apply mario_vy; landing (stomp chain reset), head hit (block trigger).  
; The pit test is done by CheckEnd in states.asm.

MoveMarioY:
        push ax
        push bx
        push cx
        push dx
        push si
        push mario_yf
        push word [mario_vy]
        call AddFixed
        mov  byte [on_ground],0
        cmp  word [mario_vy],0
        jge  .tr3
        jmp  .rising
.tr3:
        mov  ax,[mario_x]               ; falling: look at the row below the feet
        add  ax,2
        push ax
        push word [mario_y]
        call SolidAt
        test ax,ax
        jnz  .land
        mov  ax,[mario_x]
        add  ax,13
        push ax
        push word [mario_y]
        call SolidAt
        test ax,ax
        jnz  .tr4
        jmp  .done
.tr4:
.land:  mov  ax,[mario_y]
        and  ax,0FFF0h                  ; stand exactly on top of the tile
        mov  [mario_y],ax
        mov  word [mario_yf],0
        mov  word [mario_vy],0
        mov  byte [on_ground],1
        mov  word [stomp_chain],0
        jmp  .done
.rising:
        mov  bx,[mario_y]
        sub  bx,[mario_h]               ; y of the top of the head
        xor  si,si
.try:   mov  al,[head_offsets+si]       ; centre first, then the two corners
        xor  ah,ah
        add  ax,[mario_x]
        mov  cx,ax
        push cx
        push bx
        call SolidAt
        test ax,ax
        jnz  .headhit
        inc  si
        cmp  si,3
        jb   .try
        jmp  .done
.headhit:
        mov  ax,bx
        and  ax,0FFF0h
        add  ax,16                      ; just below the solid tile
        add  ax,[mario_h]
        mov  [mario_y],ax
        mov  word [mario_yf],0
        mov  word [mario_vy],0          ; he starts falling
        mov  ax,cx
        shr  ax,4                       ; tile column
        mov  dx,bx
        shr  dx,4                       ; tile row
        push ax
        push dx
        call HitBlock
.done:  pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret


; RectOverlap(ax,ay,aw,ah, bx,by,bw,bh) - do two rectangles overlap?
; In : [bp+18]=ax [bp+16]=ay [bp+14]=aw [bp+12]=ah
;      [bp+10]=bx [bp+8]=by  [bp+6]=bw  [bp+4]=bh
; Out: AX=1 overlap, 0 not     Changes: AX only

RectOverlap:
        push bp
        mov  bp,sp
        mov  ax,[bp+18]
        add  ax,[bp+14]                 ; a right
        cmp  [bp+10],ax
        jge  .no                        ; b starts right of a
        mov  ax,[bp+10]
        add  ax,[bp+6]                  ; b right
        cmp  [bp+18],ax
        jge  .no
        mov  ax,[bp+16]
        add  ax,[bp+12]                 ; a bottom
        cmp  [bp+8],ax
        jge  .no
        mov  ax,[bp+8]
        add  ax,[bp+4]                  ; b bottom
        cmp  [bp+16],ax
        jge  .no
        mov  ax,1
        jmp  .out
.no:    xor  ax,ax
.out:   pop  bp
        ret  16


; CheckFlag - is Mario's right edge in the flag pole column?
; Out: AX=1 touched (flag_row = map row of his feet, 2..8) else 0
CheckFlag:
        push bx
        push cx
        push dx
        push si
        mov  si,[mario_x]
        add  si,13
        mov  bx,[mario_y]
        dec  bx                         ; feet row first, then upward
        mov  cx,3
.look:  push si
        push bx
        call GetTile
        cmp  ax,T_FLAG
        je   .hit
        mov  dx,[mario_h]
        shr  dx,1
        sub  bx,dx
        loop .look
        xor  ax,ax
        jmp  .out
.hit:   mov  ax,[mario_y]
        dec  ax
        shr  ax,4
        cmp  ax,2
        jae  .row
        mov  ax,2
.row:   mov  [flag_row],ax
        mov  ax,1
.out:   pop  si
        pop  dx
        pop  cx
        pop  bx
        ret

head_offsets    db 8, 2, 13
