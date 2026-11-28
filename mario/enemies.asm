; ResetEnemies - rebuild enemy_table from enemy_start, empty mushrooms/pop-up
ResetEnemies:
        push ax
        push bx
        push cx
        push si
        push di
        cld
        xor  ax,ax
        mov  di,enemy_table
        mov  cx,(ENEMY_COUNT*E_SIZE)/2
        rep  stosw
        mov  di,mush_table
        mov  cx,(MUSH_COUNT*E_SIZE)/2
        rep  stosw
        mov  word [pop_timer],0
        mov  si,enemy_start
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT

.next:  lodsw
        mov  [bx+E_TYPE],ax
        lodsw
        mov  [bx+E_X],ax
        lodsw
        mov  [bx+E_Y],ax
        mov  word [bx+E_STATE],ES_WAIT
        mov  word [bx+E_DIR],-1
        add  bx,E_SIZE
        dec  cx
        jnz  .next
        pop  di
        pop  si
        pop  cx
        pop  bx
        pop  ax
        ret

; MoveEntity(record, speed, edge) - walk, turn at walls, fall, land
; Moves horizontally by dir*speed (8.8), turns around on a solid tile ahead,
; applies gravity and lands on solid tiles.  If edge<>0 the entity also turns
; around at the end of a platform (Koopa, shells do not use it).
; In : [bp+8]=record [bp+6]=speed [bp+4]=edge      Out: record   Changes: none
MoveEntity:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push si
        mov  bx,[bp+8]
        mov  ax,[bp+6]
        cmp  word [bx+E_DIR],0
        jg   .pos
        neg  ax
.pos:   lea  si,[bx+E_XF]
        push si
        push ax
        call AddFixed
        mov  ax,[bx+E_X]                ; probe the leading edge at mid height
        cmp  word [bx+E_DIR],0
        jl   .probe
        add  ax,15
.probe: mov  cx,[bx+E_Y]
        sub  cx,8
        push ax
        push cx
        call SolidAt
        test ax,ax
        jz   .grav
        neg  word [bx+E_DIR]            ; hit a wall: turn and back out
        mov  ax,[bx+E_X]
        cmp  word [bx+E_DIR],0
        jl   .wasright
        and  ax,0FFF0h                  ; was moving left
        add  ax,16
        jmp  .setx

.wasright:
        add  ax,15
        and  ax,0FFF0h
        sub  ax,16
.setx:  mov  [bx+E_X],ax
        mov  word [bx+E_XF],0

.grav:  mov  ax,[bx+E_VY]
        add  ax,GRAVITY
        cmp  ax,MAX_FALL
        jle  .gok
        mov  ax,MAX_FALL

.gok:   mov  [bx+E_VY],ax
        lea  si,[bx+E_YF]
        push si
        push ax
        call AddFixed
        cmp  word [bx+E_VY],0
        jge  .tr1
        jmp  .out

.tr1:
        mov  ax,[bx+E_X]
        add  ax,8
        push ax
        push word [bx+E_Y]
        call SolidAt
        test ax,ax
        jz   .out                       ; nothing below: keep falling
        mov  ax,[bx+E_Y]
        and  ax,0FFF0h
        mov  [bx+E_Y],ax
        mov  word [bx+E_YF],0
        mov  word [bx+E_VY],0
        cmp  word [bp+4],0
        je   .out
        mov  ax,[bx+E_X]                ; platform edge check (Koopa)
        cmp  word [bx+E_DIR],0
        jg   .aheadr
        dec  ax
        jmp  .look
.aheadr:
        add  ax,16

.look:  push ax
        push word [bx+E_Y]
        call SolidAt
        test ax,ax
        jnz  .out
        neg  word [bx+E_DIR]            ; no floor ahead: turn around

.out:   pop  si
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  6

; EnemyBump(record) - turn around when walking into another enemy

EnemyBump:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        mov  si,[bp+4]
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT
.next:  cmp  bx,si
        jne  .tr2
        jmp  .skip
.tr2:
        cmp  word [bx+E_TYPE],ET_NONE
        jne  .tr3
        jmp  .skip
.tr3:
        cmp  word [bx+E_STATE],ES_WAIT
        jne  .tr4
        jmp  .skip
.tr4:
        cmp  word [bx+E_STATE],ES_FLAT
        jne  .tr5
        jmp  .skip
.tr5:
        mov  ax,[bx+E_Y]
        sub  ax,[si+E_Y]
        cmp  ax,8
        jg   .skip
        cmp  ax,-8
        jl   .skip
        mov  dx,[bx+E_X]
        sub  dx,[si+E_X]                ; other minus me
        cmp  dx,14
        jg   .skip
        cmp  dx,-14
        jl   .skip
        cmp  word [si+E_DIR],0
        jg   .right
        test dx,dx
        jns  .skip                      ; moving left but other is not on the left
        jmp  .flip
.right: test dx,dx
        jle  .skip
.flip:  neg  word [si+E_DIR]
        jmp  .out
.skip:  add  bx,E_SIZE
        dec  cx
        jz   .tr6
        jmp  .next
.tr6:
.out:   pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  2

; ShellKills(record) - a sliding shell removes every walking enemy it touches
; (+500 points each)
ShellKills:
        push bp
        mov  bp,sp
        push ax
        push bx
        push cx
        push dx
        push si
        mov  si,[bp+4]
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT

.next:  cmp  bx,si
        je   .skip
        cmp  word [bx+E_TYPE],ET_NONE
        je   .skip
        cmp  word [bx+E_STATE],ES_WALK
        jne  .skip
        mov  ax,[bx+E_Y]
        sub  ax,[si+E_Y]
        cmp  ax,12
        jg   .skip
        cmp  ax,-12
        jl   .skip
        mov  dx,[bx+E_X]
        sub  dx,[si+E_X]
        cmp  dx,14
        jg   .skip
        cmp  dx,-14
        jl   .skip
        mov  word [bx+E_TYPE],ET_NONE   ; defeated
        push 500
        call AddScore

.skip:  add  bx,E_SIZE
        dec  cx
        jz   .tr7
        jmp  .next
.tr7:
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        pop  bp
        ret  2

; UpdateEnemies - frame step 4: activation, walking, shells, removal
; An enemy waits until it is within one tile of the right screen edge.
UpdateEnemies:
        push ax
        push bx
        push cx
        push dx
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT
.loop:  cmp  word [bx+E_TYPE],ET_NONE
        jne  .tr8
        jmp  .next
.tr8:
        mov  ax,[bx+E_X]
        sub  ax,[camera_x]              ; screen x
        cmp  word [bx+E_STATE],ES_WAIT
        jne  .active
        cmp  ax,SCREEN_W+16
        jl   .tr9
        jmp  .next
.tr9:
        mov  word [bx+E_STATE],ES_WALK  ; came into range: start walking
        mov  word [bx+E_DIR],-1
        jmp  .next
.active:
        cmp  ax,-32
        jge  .tr10
        jmp  .remove ; far left of the camera
.tr10:
        cmp  word [bx+E_Y],232
        jle  .tr11
        jmp  .remove ; fell below the map
.tr11:
        mov  ax,[bx+E_STATE]
        cmp  ax,ES_WALK
        je   .walk
        cmp  ax,ES_FLAT
        je   .flat
        cmp  ax,ES_SHELL
        je   .shell
        
        ;sliding shell
        push bx
        push SHELL_SPD
        push 0
        call MoveEntity
        cmp  word [bx+E_TIMER],0
        jle  .kills
        dec  word [bx+E_TIMER]          ; kick grace counts down
.kills: push bx
        call ShellKills
        jmp  .next
.walk:  mov  ax,GOOMBA_SPD
        xor  dx,dx
        cmp  word [bx+E_TYPE],ET_GOOMBA
        je   .wmove
        mov  ax,KOOPA_SPD
        mov  dx,1                       ; Koopa also turns at platform edges
.wmove: push bx
        push ax
        push dx
        call MoveEntity
        push bx
        call EnemyBump
        jmp  .next
.flat:  dec  word [bx+E_TIMER]
        jnz  .next
        jmp  .remove
.shell: push bx
        push 0
        push 0
        call MoveEntity                 ; speed 0: only gravity
        jmp  .next
.remove:
        mov  word [bx+E_TYPE],ET_NONE
.next:  add  bx,E_SIZE
        dec  cx
        jz   .tr12
        jmp  .loop
.tr12:
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

; MarioHitsRec(record) - rectangle-overlap test, Mario vs an entity record
; Out: AX=1 overlap
MarioHitsRec:
        push bp
        mov  bp,sp
        push bx
        mov  bx,[bp+4]
        mov  ax,[mario_x]
        add  ax,2
        push ax
        mov  ax,[mario_y]
        sub  ax,[mario_h]
        push ax
        push 12
        push word [mario_h]
        mov  ax,[bx+E_X]
        add  ax,2
        push ax
        mov  ax,[bx+E_Y]
        sub  ax,16
        push ax
        push 12
        push 16
        call RectOverlap
        pop  bx
        pop  bp
        ret  2

; StompScore - award the next stomp-chain value, bounce Mario, chain + 1
; Chain table: 100 200 400 500 800 1000 2000 4000 5000 8000, then 1-UP.
StompScore:
        push ax
        push bx
        mov  bx,[stomp_chain]
        cmp  bx,10
        jae  .oneup
        shl  bx,1
        push word [chain_points+bx]
        call AddScore
        jmp  .inc
.oneup: call AddLife
.inc:   cmp  word [stomp_chain],255
        jae  .bounce
        inc  word [stomp_chain]
.bounce:
        mov  word [mario_vy],BOUNCE
        cmp  byte [key_table+SC_SPACE],0
        je   .done
        mov  word [mario_vy],BOUNCE_HI  ; jump key held = higher bounce
.done:  pop  bx
        pop  ax
        ret

; HurtMario - enemy contact without a stomp
; Invulnerable: nothing.  HP 2: becomes Small with feet fixed + 2 s blink.
HurtMario:
        cmp  word [state],ST_PLAYING
        jne  .done
        cmp  word [invuln_timer],0
        jne  .done
        cmp  word [hp],2
        jne  .die
        push 1
        call SetHP
        mov  word [invuln_timer],INVULN_FRAMES
        ret
.die:   push 0
        call StartDeath
.done:  ret

; ResolveEnemies - frame step 5 for enemies: stomp, kick, hurt
ResolveEnemies:
        push ax
        push bx
        push cx
        push dx
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT
.loop:  cmp  word [state],ST_PLAYING
        je   .tr13
        jmp  .out ; Mario already died this frame
.tr13:
        cmp  word [bx+E_TYPE],ET_NONE
        jne  .tr14
        jmp  .next
.tr14:
        mov  ax,[bx+E_STATE]
        cmp  ax,ES_WALK
        je   .test
        cmp  ax,ES_SHELL
        je   .test
        cmp  ax,ES_SLIDE
        je   .tr15
        jmp  .next
.tr15:
        cmp  word [bx+E_TIMER],0
        jle  .tr16
        jmp  .next ; kick grace: shell ignores Mario
.tr16:
.test:  push bx
        call MarioHitsRec
        test ax,ax
        jnz  .tr17
        jmp  .next
.tr17:
        cmp  word [bx+E_STATE],ES_SHELL
        jne  .tr18
        jmp  .kick ; stationary shell: kick it
.tr18:
        cmp  word [mario_vy],0
        jg   .tr19
        jmp  .hurt ; not moving down: no stomp
.tr19:
        mov  ax,[bx+E_Y]
        sub  ax,8                       ; upper half of the enemy ends here
        cmp  [mario_prev_y],ax
        jle  .tr20
        jmp  .hurt ; feet were not above the upper half
.tr20:
        mov  ax,[bx+E_Y]                ; ---- stomp: stand on top of it
        sub  ax,16
        mov  [mario_y],ax
        mov  word [mario_yf],0
        call StompScore
        cmp  word [bx+E_STATE],ES_SLIDE
        je   .stopshell
        cmp  word [bx+E_TYPE],ET_GOOMBA
        je   .flatten
        mov  word [bx+E_STATE],ES_SHELL ; Koopa becomes a stationary shell
        jmp  .next
.flatten:
        mov  word [bx+E_STATE],ES_FLAT
        mov  word [bx+E_TIMER],FLAT_FRAMES
        jmp  .next
.stopshell:
        mov  word [bx+E_STATE],ES_SHELL
        jmp  .next
.kick:  push 400
        call AddScore
        mov  word [bx+E_STATE],ES_SLIDE
        mov  word [bx+E_TIMER],KICK_GRACE
        mov  ax,[bx+E_X]
        add  ax,8
        mov  dx,[mario_x]
        add  dx,8
        mov  word [bx+E_DIR],1          ; slide away from Mario
        cmp  ax,dx
        jge  .next
        mov  word [bx+E_DIR],-1
        jmp  .next
.hurt:  call HurtMario
.next:  add  bx,E_SIZE
        dec  cx
        jz   .tr21
        jmp  .loop
.tr21:
.out:   pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

; DrawEnemies - draw every active enemy / shell (sprite clips at the edges)
DrawEnemies:
        push ax
        push bx
        push cx
        push dx
        push si
        mov  bx,enemy_table
        mov  cx,ENEMY_COUNT
.loop:  cmp  word [bx+E_TYPE],ET_NONE
        jne  .tr22
        jmp  .next
.tr22:
        cmp  word [bx+E_STATE],ES_WAIT
        jne  .tr23
        jmp  .next
.tr23:
        xor  dx,dx
        mov  si,spr_goomba
        mov  ax,[bx+E_STATE]
        cmp  word [bx+E_TYPE],ET_KOOPA
        je   .koopa
        cmp  ax,ES_FLAT
        jne  .gwalk
        mov  si,spr_goomba_flat
        jmp  .draw
.gwalk: test byte [tick_count],8        ; walking animation: mirror now and then
        jz   .draw
        mov  dx,SF_MIRROR
        jmp  .draw
.koopa: mov  si,spr_koopa
        cmp  ax,ES_WALK
        jne  .shell
        cmp  word [bx+E_DIR],0
        jg   .draw
        mov  dx,SF_MIRROR
        jmp  .draw
.shell: mov  si,spr_shell
.draw:  mov  ax,[bx+E_X]
        sub  ax,[camera_x]
        push ax
        mov  ax,[bx+E_Y]
        sub  ax,16
        push ax
        push si
        push dx
        call DrawSprite
.next:  add  bx,E_SIZE
        dec  cx
        jz   .tr24
        jmp  .loop
.tr24:
        pop  si
        pop  dx
        pop  cx
        pop  bx
        pop  ax
        ret

chain_points    dw 100,200,400,500,800,1000,2000,4000,5000,8000
enemy_table     times ENEMY_COUNT*E_SIZE db 0
