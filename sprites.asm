DecodeSprites:
        push ax
        push cx
        push si
        cmp  byte [sprites_decoded],0
        jne  .done
        mov  byte [sprites_decoded],1
        mov  si,sprite_art_start
        mov  cx,sprite_art_end - sprite_art_start

.next:  mov  al,[si]
        cmp  al,'.'
        je   .zero
        cmp  al,'9'
        ja   .letter
        sub  al,'0'
        jmp  .store

.letter:
        sub  al,'A'-10
        jmp  .store

.zero:  xor  al,al

.store: mov  [si],al
        inc  si
        loop .next

.done:  pop  si
        pop  cx
        pop  ax
        ret

; DrawSprite(x, y, address, flags)
DrawSprite:
        push bp
        mov  bp,sp
        sub  sp,8
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es
        mov  ax,[bp+4]
        mov  [bp-8],ax
        test ax,SF_BLINK
        jz   .noblink
        test byte [tick_count],2
        jz   .tr1
        jmp  .exit ; invisible on alternate frame pairs
.tr1:

.noblink:
        mov  dx,16                      ; height
        test word [bp-8],SF_TALL
        jz   .h16
        mov  dx,32

.h16:   mov  si,[bp+6]                  ; bitmap
        mov  bx,[bp+8]                  ; y
        test bx,bx
        jns  .topok
        mov  cx,bx
        neg  cx                         ; rows cut off at the top
        cmp  cx,dx
        jl   .tr2
        jmp  .exit
.tr2:
        sub  dx,cx
        shl  cx,4                       ; 16 bytes per row
        add  si,cx
        xor  bx,bx

.topok: mov  cx,bx
        add  cx,dx
        cmp  cx,SCREEN_H
        jle  .botok
        mov  dx,SCREEN_H
        sub  dx,bx
        jg   .tr3
        jmp  .exit
.tr3:

.botok: mov  [bp-6],dx
        mov  ax,[bp+10]                 ; x
        xor  cx,cx                      ; first column
        mov  dx,16                      ; end column
        test ax,ax
        jns  .leftok
        mov  cx,ax
        neg  cx
        cmp  cx,16
        jl   .tr4
        jmp  .exit
.tr4:
.leftok:
        mov  di,ax
        add  di,16
        cmp  di,SCREEN_W
        jle  .rightok
        mov  dx,SCREEN_W
        sub  dx,ax
        jg   .tr5
        jmp  .exit
.tr5:
.rightok:
        mov  [bp-2],cx
        mov  [bp-4],dx
        mov  di,bx
        shl  bx,8
        shl  di,6
        add  di,bx
        add  di,ax                      ; di = y*320 + x
        mov  es,[draw_seg]
        cld
.rowloop:
        push si
        push di
        mov  cx,[bp-4]
        sub  cx,[bp-2]                  ; visible columns
        add  di,[bp-2]
        test word [bp-8],SF_MIRROR
        jnz  .mirror
        add  si,[bp-2]
        test word [bp-8],SF_OPAQUE
        jz   .tpix
        rep  movsb                      ; tiles: whole row in one go
        jmp  .rowdone
.tpix:  lodsb
        test al,al
        jz   .tskip                     ; colour 0 = transparent
        mov  [es:di],al
.tskip: inc  di
        loop .tpix
        jmp  .rowdone
.mirror:
        add  si,15
        sub  si,[bp-2]                  ; start at column 15 - first
.mpix:  mov  al,[si]
        dec  si
        test al,al
        jz   .mskip
        mov  [es:di],al
.mskip: inc  di
        loop .mpix
.rowdone:
        pop  di
        pop  si
        add  si,16
        add  di,SCREEN_W
        dec  word [bp-6]
        jz   .tr6
        jmp  .rowloop
.tr6:
.exit:  pop  es
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        mov  sp,bp
        pop  bp
        ret  8

; DrawMario - choose form/pose and draw Mario at screen_x = mario_x - camera_x
; Pose: jump in the air, run (alternating with stand) when moving, else stand.
; In: none  Out: none  Changes: none
DrawMario:
        push ax
        push bx
        push dx
        xor  bx,bx                      ; pose 0 = stand
        cmp  byte [on_ground],0
        jne  .ground
        mov  bx,2                       ; jump
        jmp  .pose
.ground:
        cmp  word [mario_vx],0
        je   .pose
        test byte [tick_count],4        ; walking animation
        jz   .pose
        mov  bx,1                       ; run frame
.pose:  shl  bx,1
        xor  dx,dx                      ; flags
        mov  ax,[mario_x]
        sub  ax,[camera_x]
        push ax                         ; x
        mov  ax,[mario_y]
        sub  ax,[mario_h]
        push ax                         ; y = top
        cmp  word [hp],2
        je   .super
        push word [mario_small+bx]
        jmp  .flags
.super: push word [mario_super+bx]
        or   dx,SF_TALL
.flags: cmp  byte [facing],0
        jne  .right
        or   dx,SF_MIRROR               ; art faces right; mirror for left
.right: cmp  word [invuln_timer],0
        je   .noblink
        or   dx,SF_BLINK
.noblink:
        push dx
        call DrawSprite
        pop  dx
        pop  bx
        pop  ax
        ret

sprites_decoded db 0
mario_small     dw spr_mario_stand, spr_mario_run, spr_mario_jump
mario_super     dw spr_super_stand, spr_super_run, spr_super_jump
