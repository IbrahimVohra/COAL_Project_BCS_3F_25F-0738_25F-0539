; display
SCREEN_W        equ 320
SCREEN_H        equ 200
TILE            equ 16
MAP_W           equ 60
MAP_H           equ 12
MAP_SIZE        equ 720
LEVEL_PX        equ 960
CAM_MAX         equ 640                 ; LEVEL_PX - 320
CAM_FOLLOW      equ 160
PIT_Y           equ 192
FB_PARAS        equ 4000                ; 64000 bytes / 16
VGA_SEG         equ 0A000h

; colours (our own 16-entry palette)
C_BLACK         equ 0                   ; also the transparent index in sprites
C_SKY           equ 1
C_BRICK         equ 2
C_SKIN          equ 3
C_RED           equ 4
C_BLUE          equ 5
C_BROWN         equ 6
C_GREEN         equ 7
C_LGREEN        equ 8
C_YELLOW        equ 9
C_ORANGE        equ 10
C_WHITE         equ 11
C_GRAY          equ 12
C_DGREEN        equ 13
C_TAN           equ 14
C_DGRAY         equ 15

; ---- scan codes ----------------------------------------------------------
SC_ESC          equ 01h
SC_ENTER        equ 1Ch
SC_P            equ 19h
SC_LSHIFT       equ 2Ah
SC_SPACE        equ 39h
SC_LEFT         equ 4Bh
SC_RIGHT        equ 4Dh
SC_UP           equ 48h
SC_DOWN         equ 50h
SC_F1           equ 3Bh                 ; debug: time = 5 s
SC_F2           equ 3Ch                 ; debug: coins = 99
SC_F3           equ 3Dh                 ; debug: colour test on title screen

; ---- tile codes ----------------------------------------------------------
T_SKY           equ 0
T_GROUND        equ 1
T_BRICK         equ 2
T_QCOIN         equ 3
T_QMUSH         equ 4
T_EMPTY         equ 5
T_PIPE_TL       equ 6
T_PIPE_TR       equ 7
T_PIPE_BL       equ 8
T_PIPE_BR       equ 9
T_STAIR         equ 10                  ; last solid code
T_COIN          equ 11
T_FLAG          equ 12

; ---- game states ---------------------------------------------------------
ST_TITLE        equ 0
ST_PLAYING      equ 1
ST_PAUSED       equ 2
ST_DYING        equ 3
ST_LIFELOST     equ 4
ST_WIN          equ 5
ST_COMPLETE     equ 6
ST_GAMEOVER     equ 7
ST_EXIT         equ 8

; ---- physics (8.8 fixed point, about 30 FPS) ------------------------------
ACCEL           equ 0030h
FRICTION        equ 0018h
BRAKE           equ 0060h
MAX_WALK        equ 0200h               ; 2.0 px/frame (was 1.5)
MAX_RUN         equ 0300h               ; 3.0 px/frame (was 2.5)
GRAVITY         equ 0040h
JUMP_V          equ 0FA80h              ; -5.5
JUMP_CUT        equ 0FE00h              ; -2.0
MAX_FALL        equ 0400h
BOUNCE          equ 0FD00h              ; -3.0
BOUNCE_HI       equ 0FB80h              ; -4.5 (jump key held)
DEATH_HOP       equ 0FB00h              ; -5.0 (hop of about 50 px)
GOOMBA_SPD      equ 0080h
KOOPA_SPD       equ 00C0h
SHELL_SPD       equ 0300h
MUSH_SPD        equ 0100h

; ---- game limits ---------------------------------------------------------
START_LIVES     equ 3
MAX_LIVES       equ 99
LEVEL_TIME      equ 300
TICKS_PER_SEC   equ 30
PIT_DIV         equ 39773               ; 1193182 / 30 Hz
INVULN_FRAMES   equ 60                  ; 2 s
FLAT_FRAMES     equ 30                  ; 1 s
KICK_GRACE      equ 8
DEATH_FRAMES    equ 48                  ; about 1.5 s
LIFE_FRAMES     equ 60                  ; 2 s
SLIDE_FRAMES    equ 30
WALK_FRAMES     equ 36
MAX_SCORE_LO    equ 423Fh               ; 999,999 = 000F423Fh
MAX_SCORE_HI    equ 000Fh
MARIO_START_X   equ 32
MARIO_START_Y   equ 160                 ; feet y (top of ground row 10)
POLE_X          equ 890                 ; Mario x while on the pole
BASE_Y          equ 144                 ; top of the pole base block

; ---- sprite flags --------------------------------------------------------
SF_MIRROR       equ 1
SF_BLINK        equ 2
SF_OPAQUE       equ 4
SF_TALL         equ 8                   ; 16 x 32 instead of 16 x 16

; ---- enemy / mushroom records (20 bytes each) ----------------------------
E_TYPE          equ 0
E_STATE         equ 2
E_XF            equ 4                   ; x fraction, x whole must follow
E_X             equ 6
E_YF            equ 8                   ; y fraction, y whole must follow
E_Y             equ 10                  ; y of the FEET
E_VY            equ 12
E_DIR           equ 14                  ; +1 right, -1 left
E_TIMER         equ 16
E_SIZE          equ 20

ET_NONE         equ 0
ET_GOOMBA       equ 1
ET_KOOPA        equ 2
ET_MUSH         equ 3

ES_WAIT         equ 0
ES_WALK         equ 1
ES_FLAT         equ 2
ES_SHELL        equ 3
ES_SLIDE        equ 4

ENEMY_COUNT     equ 6
MUSH_COUNT      equ 2
