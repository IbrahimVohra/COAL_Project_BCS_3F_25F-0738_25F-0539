; UpdateCamera
; 1. screen_x = mario_x - camera_x
; 2. if screen_x > 160 then new = mario_x - 160
; 3. clamp new to 640         
; 4. camera_x = max(camera_x, new)
; 5. left wall: mario_x < camera_x -> mario_x = camera_x, speed 0
; In: none  Out: camera_x (and mario_x/mario_xf/mario_vx on the wall)
; Changes: none


UpdateCamera:
        push ax
        mov  ax,[mario_x]
        sub  ax,[camera_x]              ; screen_x
        cmp  ax,CAM_FOLLOW
        jle  .wall

        mov  ax,[mario_x]
        sub  ax,CAM_FOLLOW              ; new_camera
        cmp  ax,CAM_MAX
        jle  .lim
        mov  ax,CAM_MAX
.lim:   cmp  ax,[camera_x]
        jle  .wall                      ; never decrease
        mov  [camera_x],ax
.wall:  mov  ax,[camera_x]
        cmp  [mario_x],ax
        jge  .done
        mov  [mario_x],ax               ; invisible wall on the left
        mov  word [mario_xf],0
        mov  word [mario_vx],0
.done:  pop  ax
        ret

camera_x        dw 0
