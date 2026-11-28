; HitBlock(column, row) - Mario's head hit this tile from below
; Brick: Super breaks it (+50), Small nothing.  "?" coin: becomes empty, +200,
; coins + 1.  "?" mushroom: becomes empty, mushroom appears on top.
; In : [bp+6]=column [bp+4]=row     Out: working map changed    Changes: none
HitBlock:
        push bp
        mov  bp,sp
        push ax
        push bx
        push dx
        mov  ax,[bp+6]
        mov  bx,[bp+4]
        cmp  ax,MAP_W
        jb   .tr1
        jmp  .out
.tr1:
        cmp  bx,MAP_H
        jb   .tr2
        jmp  .out
.tr2:
        mov  dx,bx
        shl  bx,6
        shl  dx,2
        sub  bx,dx
        add  bx,ax                      ; offset = row*60 + column
        mov  al,[work_map+bx]
        cmp  al,T_BRICK
        jne  .q1
        cmp  word [hp],2
        je   .tr3
        jmp  .out ; Small Mario: the brick stays
.tr3:
        mov  byte [work_map+bx],T_SKY
        push 50
        call AddScore
        jmp  .out
.q1:    cmp  al,T_QCOIN
        jne  .q2
        mov  byte [work_map+bx],T_EMPTY
        push 200
        call AddScore
        call AddCoin
        mov  ax,[bp+6]
        shl  ax,4
        mov  [pop_x],ax                 ; little coin pops out above the block
        mov  ax,[bp+4]
        shl  ax,4
        sub  ax,16
        mov  [pop_y],ax
        mov  word [pop_timer],12
        jmp  .out

.q2:    cmp  al,T_QMUSH
        jne  .out
        mov  byte [work_map+bx],T_EMPTY
        mov  ax,[bp+6]
        shl  ax,4
        push ax                         ; x
        mov  ax,[bp+4]
        shl  ax,4
        push ax                         ; feet y = top of the block
        call SpawnMushroom

.out:   pop  dx
        pop  bx
        pop  ax
        pop  bp
        ret  4

; SpawnMushroom(x, feet_y) - put a mushroom in a free slot, moving right
SpawnMushroom:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        mov  bx,mush_table
        mov  cx,MUSH_COUNT

.find:  cmp  word [bx+E_TYPE],ET_NONE
        je   .use
        add  bx,E_SIZE
        dec  cx
        jnz  .find
        jmp  .out

.use:   mov  word [bx+E_TYPE],ET_MUSH
        mov  word [bx+E_STATE],ES_WALK
        mov  word [bx+E_XF],0
        mov  ax,[bp+6]
        mov  [bx+E_X],ax
        mov  word [bx+E_YF],0
        mov  ax,[bp+4]
        mov  [bx+E_Y],ax
        mov  word [bx+E_VY],0
        mov  word [bx+E_DIR],1
        mov  word [bx+E_TIMER],0

.out:   pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  4

UpdateMushrooms:
        push ax
        push bx
        push cx
        mov  bx,mush_table
        mov  cx,MUSH_COUNT

.loop:  cmp  word [bx+E_TYPE],ET_NONE
        je   .next
        push bx
        push MUSH_SPD
        push 0
        call MoveEntity
        cmp  word [bx+E_Y],232
        jg   .remove
        mov  ax,[bx+E_X]
        sub  ax,[camera_x]
        cmp  ax,-32
        jl   .remove
        push bx
        call MarioHitsRec
        test ax,ax
        jz   .next
        push 1000
        call AddScore                   ; a Super Mario only gets the points
        cmp  word [hp],2
        je   .remove
        push 2
        call SetHP                      ; feet stay fixed (mario_y = feet)
.remove:
        mov  word [bx+E_TYPE],ET_NONE

.next:  add  bx,E_SIZE
        dec  cx
        jz   .tr4
        jmp  .loop
.tr4:
        pop  cx
        pop  bx
        pop  ax
        ret

; CoinAt(px, py) - collect a coin tile at this pixel (+200, coins + 1)
CoinAt:
        push bp
        mov  bp,sp
        push ax
        push word [bp+6]
        push word [bp+4]
        call GetTile
        cmp  ax,T_COIN
        jne  .out
        push word [bp+6]
        push word [bp+4]
        push T_SKY
        call SetTile
        push 200
        call AddScore
        call AddCoin

.out:   pop  ax
        pop  bp
        ret  4

; CollectCoins - test Mario's body (left and right edge at top, middle, feet)
CollectCoins:
        push ax
        push bx
        push cx
        push dx
        mov  bx,[mario_y]
        sub  bx,[mario_h]               ; top
        mov  cx,[mario_h]
        shr  cx,1
        add  cx,bx                      ; middle
        mov  dx,[mario_y]
        dec  dx                         ; last row of the feet
        mov  ax,[mario_x]
        add  ax,2
        push ax
        push bx
        call CoinAt
        push ax
        push cx
        call CoinAt
        push ax
        push dx
        call CoinAt
        mov  ax,[mario_x]
        add  ax,13
        push ax
        push bx
        call CoinAt
        push ax
        push cx
        call CoinAt
        push ax
        push dx
        call CoinAt
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

; UpdateCoinPop - move the little "coin released by a ? block" upwards
UpdateCoinPop:
        cmp  word [pop_timer],0
        je   .done
        dec  word [pop_timer]
        sub  word [pop_y],3
.done:  ret

; DrawMushrooms / DrawCoinPop - draw the items into the frame buffer
DrawMushrooms:
        push ax
        push bx
        push cx
        mov  bx,mush_table
        mov  cx,MUSH_COUNT

.loop:  cmp  word [bx+E_TYPE],ET_NONE
        je   .next
        mov  ax,[bx+E_X]
        sub  ax,[camera_x]
        push ax
        mov  ax,[bx+E_Y]
        sub  ax,16
        push ax
        push spr_mushroom
        push 0
        call DrawSprite

.next:  add  bx,E_SIZE
        dec  cx
        jnz  .loop
        pop  cx
        pop  bx
        pop  ax
        ret

DrawCoinPop:
        push ax
        cmp  word [pop_timer],0
        je   .done
        mov  ax,[pop_x]
        sub  ax,[camera_x]
        push ax
        push word [pop_y]
        push spr_coin
        push 0
        call DrawSprite

.done:  pop  ax
        ret

pop_x           dw 0
pop_y           dw 0
pop_timer       dw 0
mush_table      times MUSH_COUNT*E_SIZE db 0
