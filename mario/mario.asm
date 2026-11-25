        bits 16
        org  100h

        jmp  start                      ; execution can never fall into data

%include "consts.inc"
%include "video.asm"
%include "framebuf.asm"
%include "map.asm"
%include "leveldat.asm"
%include "font.asm"
%include "hud.asm"
%include "keyboard.asm"
%include "timer.asm"
%include "camera.asm"
%include "spritdat.asm"
%include "sprites.asm"
%include "physics.asm"
%include "collide.asm"
%include "enemies.asm"
%include "blocks.asm"
%include "screens.asm"
%include "sequence.asm"
%include "states.asm"

start:
        cld
        call AllocFrameBuffer           ; release spare memory, reserve 2nd segment
        jnc  .tr1
        jmp  .nomem
.tr1:
        call DecodeSprites              ; turn ASCII art into colour indices (once)
        call BuildLevel                 ; turn the level text into the original map
        call InstallKeyboard            ; save old INT 09h, install ours
        call InstallTimer               ; save old INT 08h, install ours, PIT 30 Hz
        call SetMode13
        call InitPalette
        call NewGame                    ; score, coins, lives, then ResetLevel
        push ST_TITLE
        call ChangeState
        mov  ax,[tick_count]
        mov  [last_tick],ax

; main loop: wait for a tick, run the handler of the current state
.mainloop:
        mov  ax,[last_tick]
.wait:
        hlt                          
        cmp  ax,[tick_count]
        je   .wait                      ; speed is set by the timer, not the PC
        mov  ax,[tick_count]
        mov  [last_tick],ax
        cmp  word [state],ST_PLAYING
        je   .dispatch
        mov  byte [sec_pending],0       ; clock only runs while PLAYING
.dispatch:
        mov  bx,[state]
        cmp  bx,ST_EXIT
        je   ExitProgram
        shl  bx,1
        call word [state_table+bx]      ; jump table indexed by state
        jmp  .mainloop

.nomem:
        mov  dx,msg_nomem
        mov  ah,09h
        int  21h
        mov  ax,4C01h
        int  21h

; ExitProgram - the single exit path: restore timer, keyboard, text mode, DOS
ExitProgram:
        call RestoreTimer
        call RestoreKeyboard
        call SetTextMode
        mov  ax,4C00h
        int  21h

msg_nomem       db 'Not enough memory for the frame buffer.',13,10,'$'
