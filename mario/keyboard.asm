InstallKeyboard:
        push ax
        push bx
        push dx
        push es
        mov  ax,3509h                   
        int  21h
        mov  [old_kb_off],bx
        mov  [old_kb_seg],es
        mov  dx,KeyboardISR
        mov  ax,2509h                  
        int  21h
        pop  es
        pop  dx
        pop  bx
        pop  ax
        ret

; RestoreKeyboard - put the original INT 09h vector back (every exit path)
RestoreKeyboard:
        push ax
        push dx
        push ds
        mov  dx,[old_kb_off]
        mov  ds,[old_kb_seg]
        mov  ax,2509h
        int  21h
        pop  ds
        pop  dx
        pop  ax
        ret

; KeyboardISR - hardware keyboard interrupt
; Reads port 60h; E0h prefix is ignored; bit 7 = release.  Sends EOI, IRET.
KeyboardISR:
        push ax
        push bx
        push ds
        push cs
        pop  ds
        in   al,60h
        cmp  al,0E0h
        je   .eoi
        cmp  al,0E1h
        je   .eoi
        mov  bl,al
        and  bx,007Fh                   ; bx = scan code without release bit
        test al,80h
        jnz  .release
        cmp  byte [key_table+bx],0
        jne  .held                      ; auto-repeat: not a new press
        mov  byte [edge_table+bx],1
.held:  mov  byte [key_table+bx],1
        jmp  .eoi
.release:
        mov  byte [key_table+bx],0
.eoi:   mov  al,20h
        out  20h,al
        pop  ds
        pop  bx
        pop  ax
        iret

; KeyPressed(scancode) - was the key freshly pressed?  (consumes the event)
; In : [bp+4]=scan code   Out: AX=1 if pressed since last asked, else 0
KeyPressed:
        push bp
        mov  bp,sp
        push bx
        mov  bx,[bp+4]
        and  bx,007Fh
        xor  ax,ax
        cmp  byte [edge_table+bx],0
        je   .no
        mov  byte [edge_table+bx],0
        mov  ax,1
.no:    pop  bx
        pop  bp
        ret  2

; ClearEdges - forget all pending fresh-press events
ClearEdges:
        push ax
        push cx
        push di
        mov  di,edge_table
        mov  cx,128
        xor  al,al
        cld
        rep  stosb
        pop  di
        pop  cx
        pop  ax
        ret

;data
old_kb_off      dw 0
old_kb_seg      dw 0
key_table       times 128 db 0
edge_table      times 128 db 0
