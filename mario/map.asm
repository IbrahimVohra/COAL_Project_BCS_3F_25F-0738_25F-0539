
CHARSET_LEN     equ 13

; BuildLevel - convert level_text (ASCII) into orig_map (tile codes)
; In: none  Out: orig_map filled  Changes: none
BuildLevel:
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        cld
        mov  si,level_text
        mov  bx,orig_map
        mov  dx,MAP_SIZE

.next:  lodsb                           ; al = design character
        mov  di,charset
        mov  cx,CHARSET_LEN
        repne scasb                     ; search it in the character set
        mov  al,0                       ; unknown character = sky
        jne  .store
        mov  ax,CHARSET_LEN-1
        sub  ax,cx                      ; index in the set = tile code

.store: mov  [bx],al
        inc  bx
        dec  dx
        jnz  .next
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

; ResetMap - restore the working map from the original (REP MOVSB)
ResetMap:
        push cx
        push si
        push di
        cld
        mov  si,orig_map
        mov  di,work_map
        mov  cx,MAP_SIZE
        rep  movsb
        pop  di
        pop  si
        pop  cx
        ret

GetTile:
        push bp
        mov  bp,sp
        push bx
        push dx
        mov  ax,[bp+6]
        mov  bx,[bp+4]
        test ax,ax
        js   .wall
        cmp  ax,LEVEL_PX
        jae  .wall
        test bx,bx
        js   .sky
        cmp  bx,PIT_Y
        jae  .sky
        shr  ax,4                       ; column
        shr  bx,4                       ; row
        mov  dx,bx
        shl  bx,6
        shl  dx,2
        sub  bx,dx                      ; row*64 - row*4 = row*60
        add  bx,ax
        mov  al,[work_map+bx]
        xor  ah,ah
        jmp  .out

.wall:  mov  ax,T_GROUND
        jmp  .out

.sky:   xor  ax,ax

.out:   pop  dx
        pop  bx
        pop  bp
        ret  4


SetTile:
        push bp
        mov  bp,sp
        push ax
        push bx
        push dx
        mov  ax,[bp+8]
        mov  bx,[bp+6]
        cmp  ax,LEVEL_PX
        jae  .out
        cmp  bx,PIT_Y
        jae  .out
        shr  ax,4
        shr  bx,4
        mov  dx,bx
        shl  bx,6
        shl  dx,2
        sub  bx,dx
        add  bx,ax
        mov  al,[bp+4]
        mov  [work_map+bx],al
.out:   pop  dx
        pop  bx
        pop  ax
        pop  bp
        ret  6

DrawTile:
        push bp
        mov  bp,sp
        push ax
        push bx
        mov  bx,[bp+8]
        xor  ax,ax                      ; flags: transparent
        cmp  bx,T_STAIR
        ja   .flags
        mov  ax,SF_OPAQUE               ; solid tiles overwrite everything
.flags: shl  bx,1
        push word [bp+6]
        push word [bp+4]
        push word [tile_gfx+bx]
        push ax
        call DrawSprite
        pop  bx
        pop  ax
        pop  bp
        ret  6

DrawMap:
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        mov  si,[camera_x]
        mov  bx,si
        shr  bx,4                       ; bx = first world column
        and  si,15                      ; si = pixel offset
        xor  cx,cx                      ; cx = screen column 0..20
.col:   cmp  bx,MAP_W
        jae  .nextcol
        mov  dx,cx
        shl  dx,4
        sub  dx,si                      ; dx = screen x of this column
        mov  di,1                       ; rows 1..11
.row:   mov  ax,bx
        shl  ax,4
        push ax                         ; px
        mov  ax,di
        shl  ax,4
        push ax                         ; py
        call GetTile
        test ax,ax
        jz   .nextrow
        push ax                         ; code
        push dx                         ; x
        mov  ax,di
        shl  ax,4
        push ax                         ; y
        call DrawTile
.nextrow:
        inc  di
        cmp  di,MAP_H
        jb   .row
.nextcol:
        inc  bx
        inc  cx
        cmp  cx,21
        jae  .tr1
        jmp  .col
.tr1:
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

charset         db ".GB?ME[]()So|"      ; character position = tile code
tile_gfx        dw 0, gfx_ground, gfx_brick, gfx_q, gfx_q, gfx_empty
                dw gfx_ptl, gfx_ptr, gfx_pbl, gfx_pbr, gfx_stair
                dw spr_coin, gfx_pole
