; InstallTimer - save old INT 08h, install TimerISR, program PIT to 30 Hz
InstallTimer:
        push ax
        push bx
        push dx
        push es
        mov  ax,3508h
        int  21h
        mov  [old_tm_off],bx
        mov  [old_tm_seg],es
        cli
        mov  dx,TimerISR
        mov  ax,2508h
        int  21h
        mov  al,36h                     ; channel 0, lo/hi, mode 3
        out  43h,al
        mov  ax,PIT_DIV
        out  40h,al
        mov  al,ah
        out  40h,al
        sti
        pop  es
        pop  dx
        pop  bx
        pop  ax
        ret

; RestoreTimer - restore the PIT rate (65536 = 18.2 Hz) and the old vector
RestoreTimer:
        push ax
        push dx
        push ds
        cli
        mov  al,36h
        out  43h,al
        xor  al,al
        out  40h,al
        out  40h,al
        mov  dx,[old_tm_off]
        mov  ds,[old_tm_seg]
        mov  ax,2508h
        int  21h
        sti
        pop  ds
        pop  dx
        pop  ax
        ret

; TimerISR - increments tick_count, derives seconds, chains to old handler
TimerISR:
        push ax
        push ds
        push cs
        pop  ds
        inc  word [tick_count]
        inc  byte [sec_sub]
        cmp  byte [sec_sub],TICKS_PER_SEC
        jb   .nosec
        mov  byte [sec_sub],0
        inc  byte [sec_pending]         ; one real second has passed

.nosec: mov  ax,[pit_acc]
        add  ax,PIT_DIV
        mov  [pit_acc],ax
        jc   .chain                     ; time for the 18.2 Hz BIOS tick
        mov  al,20h
        out  20h,al                     ; EOI
        pop  ds
        pop  ax
        iret

.chain: pop  ds
        pop  ax
        jmp  chain_old_timer            ; old handler ends with IRET

; ClockTick - called once per PLAYING frame: use up pending real seconds
; In: none  Out: none  Changes: none (time_left counts down, never below 0)
ClockTick:

.again: cmp  byte [sec_pending],0
        je   .done
        dec  byte [sec_pending]
        cmp  word [time_left],0
        je   .again
        dec  word [time_left]
        jmp  .again

.done:  ret

tick_count      dw 0
last_tick       dw 0
pit_acc         dw 0
sec_sub         db 0
sec_pending     db 0
time_left       dw LEVEL_TIME
chain_old_timer:                        ; JMP FAR opcode followed by the saved
                db 0EAh                 ; vector: executing it jumps to the
old_tm_off      dw 0                    ; original BIOS INT 08h handler
old_tm_seg      dw 0