level_text:
        db "............................................................"   ; row 0
        db "............................................................"   ; row 1
        db "........................................................|..."   ; row 2
        db "........................................................|..."   ; row 3
        db "........................................................|..."   ; row 4
        db "........................................................|..."   ; row 5
        db "........?BMB?.BBB.........M...........BBB?BB........S...|..."   ; row 6
        db ".................ooo....oo..[].....................SS...|..."   ; row 7
        db "...ooo................[]....()................ooo.SSS...|..."   ; row 8
        db "......................()....()...................SSSS...S..."   ; row 9
        db "GGGGGGGGGGGGGGGGG...GGGGGGGGGGGGG...GGGGGGGGGGGGGGGGGGGGGGGG"   ; row 10
        db "GGGGGGGGGGGGGGGGG...GGGGGGGGGGGGG...GGGGGGGGGGGGGGGGGGGGGGGG"   ; row 11

orig_map        times MAP_SIZE db 0     ; never changed after BuildLevel
work_map        times MAP_SIZE db 0     ; changed by hits and coin pick-ups

; enemy start table: type, x (pixels), y of the feet.  Records in the
; enemy table are rebuilt from it by ResetEnemies.
enemy_start:
        dw ET_GOOMBA, 224, 160
        dw ET_GOOMBA, 400, 160
        dw ET_KOOPA , 496, 160
        dw ET_GOOMBA, 608, 160          ; two Goombas close together
        dw ET_GOOMBA, 640, 160          ; (stomp chain test)
        dw ET_KOOPA , 704, 160
