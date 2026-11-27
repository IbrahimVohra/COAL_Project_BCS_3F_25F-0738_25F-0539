; AddFixed(address, velocity) - add an 8.8 signed velocity to a position pair
; The pair is [address] = fraction word (value in the HIGH byte), [address+2] = whole pixels.  whole += velocity>>8 (arithmetic), fraction += low byte<<8,
; with the carry (ADC) going into the whole part.
; In : [bp+6]=address  [bp+4]=velocity    Out: none   Changes: none
AddFixed:
        push bp
        mov  bp,sp
        push ax
        push bx
        push dx
        mov  bx,[bp+6]
        mov  ax,[bp+4]
        mov  dx,ax
        sar  dx,8                       ; signed whole pixels (floor)
        mov  ah,al
        xor  al,al                      ; fraction as high byte
        add  [bx],ax
        adc  [bx+2],dx
        pop  dx
        pop  bx
        pop  ax
        pop  bp
        ret  4

; SetHP(newhp) - set health (1 small / 2 super) and the matching height
; In : [bp+4]=1 or 2     Out: hp, mario_h     Changes: none
SetHP:
        push bp
        mov  bp,sp
        push ax
        mov  ax,[bp+4]
        mov  [hp],ax
        mov  word [mario_h],16
        cmp  ax,2
        jne  .done
        mov  word [mario_h],32
.done:  pop  ax
        pop  bp
        ret  2

; UpdateMario - one frame of hero physics (step 2-3 of the frame order)
UpdateMario:
        push ax
        push bx
        mov  ax,[mario_y]
        mov  [mario_prev_y],ax          ; for the stomp test
        mov  bx,MAX_WALK
        cmp  byte [key_table+SC_LSHIFT],0
        je   .gotmax
        mov  bx,MAX_RUN
.gotmax:
        mov  al,[key_table+SC_RIGHT]
        mov  ah,[key_table+SC_LEFT]
        cmp  al,ah
        jne  .tr1
        jmp  .friction ; both or none held
.tr1:
        test al,al
        jz   .goleft
        
        ; right
        mov  byte [facing],1
        mov  ax,[mario_vx]
        test ax,ax
        jns  .racc
        add  ax,BRAKE                   ; reversing: brake faster
        jmp  .rlim

.racc:  add  ax,ACCEL

.rlim:  cmp  ax,bx
        jg   .tr2
        jmp  .storex
.tr2:
        mov  ax,bx
        jmp  .storex
        ; ---- left
.goleft:
        mov  byte [facing],0
        neg  bx                         ; limit = -max
        mov  ax,[mario_vx]
        test ax,ax
        jle  .lacc
        sub  ax,BRAKE
        jmp  .llim

.lacc:  sub  ax,ACCEL

.llim:  cmp  ax,bx
        jge  .storex
        mov  ax,bx
        jmp  .storex
        ; ---- friction
.friction:
        mov  ax,[mario_vx]
        test ax,ax
        jz   .storex
        js   .fneg
        sub  ax,FRICTION
        jns  .storex
        xor  ax,ax
        jmp  .storex

.fneg:  add  ax,FRICTION
        js   .storex
        xor  ax,ax
.storex:
        mov  [mario_vx],ax

        ;jump
        cmp  byte [key_table+SC_SPACE],0
        jne  .spacedown
        mov  byte [jump_lock],0
        mov  ax,[mario_vy]
        cmp  ax,JUMP_CUT                ; signed: rising faster than the cut-off?
        jge  .gravity
        mov  word [mario_vy],JUMP_CUT   ; variable jump height
        jmp  .gravity
.spacedown:
        cmp  byte [on_ground],0
        je   .gravity                   ; no double jump
        cmp  byte [jump_lock],0
        jne  .gravity
        mov  byte [jump_lock],1
        mov  word [mario_vy],JUMP_V
        mov  byte [on_ground],0
.gravity:
        mov  ax,[mario_vy]
        add  ax,GRAVITY
        cmp  ax,MAX_FALL
        jle  .gok
        mov  ax,MAX_FALL
.gok:   mov  [mario_vy],ax
        call MoveMarioX
        call MoveMarioY
        pop  bx
        pop  ax
        ret

; hero data
mario_xf        dw 0                    ; x fraction  (pair: fraction, whole)
mario_x         dw MARIO_START_X
mario_yf        dw 0                    ; feet y fraction
mario_y         dw MARIO_START_Y        ; feet y, whole pixels
mario_vx        dw 0                    ; 8.8 signed
mario_vy        dw 0
mario_h         dw 16                   ; 16 small, 32 super
mario_prev_y    dw MARIO_START_Y
hp              dw 1
invuln_timer    dw 0
stomp_chain     dw 0
on_ground       db 1
jump_lock       db 0
facing          db 1                    ; 1 right, 0 left
flag_row        dw 0
