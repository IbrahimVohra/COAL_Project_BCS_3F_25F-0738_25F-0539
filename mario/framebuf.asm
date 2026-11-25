
; AllocFrameBuffer - release spare memory and reserve the frame-buffer segment
; In: none   Out: CF=1 on failure, else [fb_seg]=[draw_seg]=segment
; Changes: flags only

AllocFrameBuffer:
        push ax
        push bx
        mov  bx,1000h                   ; keep 64 KB for the program
        mov  ah,4Ah
        int  21h
        jc   .fail
        mov  bx,FB_PARAS
        mov  ah,48h
        int  21h
        jc   .fail
        mov  [fb_seg],ax
        mov  [draw_seg],ax
        clc
        jmp  .out

.fail:  stc

.out:   pop  bx
        pop  ax
        ret

; ClearFrame(colour) - REP STOSW fill of the whole frame buffer
; In : [bp+4]=colour (0..255)   Out: none   Changes: none
ClearFrame:
        push bp
        mov  bp,sp
        push ax
        push cx
        push di
        push es
        mov  es,[fb_seg]
        xor  di,di
        mov  al,[bp+4]
        mov  ah,al
        mov  cx,32000                   ; 64000 bytes as words
        cld
        rep  stosw
        pop  es
        pop  di
        pop  cx
        pop  ax
        pop  bp
        ret  2

; PresentFrame - wait for vertical retrace, copy frame buffer to video memory
; with one REP MOVSW.   In: none  Out: none  Changes: none
PresentFrame:
        push ax
        push cx
        push dx
        push si
        push di
        push ds
        push es
        mov  dx,3DAh

.w1:    in   al,dx
        test al,08h
        jnz  .w1                        ; leave any retrace in progress

.w2:    in   al,dx
        test al,08h
        jz   .w2                        ; wait for the next one
        mov  ax,[fb_seg]
        mov  ds,ax
        mov  ax,VGA_SEG
        mov  es,ax
        xor  si,si
        xor  di,di
        mov  cx,32000
        cld
        rep  movsw
        pop  es
        pop  ds
        pop  di
        pop  si
        pop  dx
        pop  cx
        pop  ax
        ret

;data
fb_seg          dw 0
draw_seg        dw 0