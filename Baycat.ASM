;***********************************************
;*                                             *
;*            BAYCAT - COMMAND                 *
;*                                             *
;*             WRITTEN 1989 BY                 *
;*                                             *
;*             LUTZ GROßHENNIG                 *
;*                                             *
;***********************************************

; OFFSETS EXEC

FORBID         = -132
PERMIT         = -138
ALLOCMEM       = -198
FREEMEM        = -210
OPENLIBRARY    = -408
CLOSELIBRARY   = -414

; OFFSETS BLITTER

BLTSIZE        = $DFF058
BLTAFWM        = $DFF044

BLTAPTH        = $DFF050
BLTBPTH        = $DFF04C
BLTCPTH        = $DFF048
BLTDPTH        = $DFF054

BLTAMOD        = $DFF064
BLTBMOD        = $DFF062
BLTCMOD        = $DFF060
BLTDMOD        = $DFF066

BLTCON0        = $DFF040
BLTCON1        = $DFF042

; VARIOUS HARDWARE REGISTERS

MOUSEBUTTON    = $BFE001
DMACON         = $DFF096
DMACONR        = $DFF002
INTENA         = $DFF09A
JOY1DAT        = $DFF00C
COLOR00        = $DFF180
VHPOSR         = $DFF006

; CONST VALUES

EXECBASE       = 4
CHIPREQUEST    = $10002

SCREENX        = 224
SCREENB        = SCREENX / 8
SCREENY        = 1280
PLANES         = 5

PLANESIZE      = (SCREENX * SCREENY) / 8
PLAYFIELD      = PLANESIZE * PLANES

MAX_SCREEN     = SCREENY - 256
MIN_SCREEN     = 0
SCROLL_SPEED   = 1

MAPCHARS       = (LEVEL_1_END - LEVEL_1) - 1

SCR2Y          = 60
PLANE          = SCREENB * SCR2Y
PLAY           = PLANE * PLANES

SHIP_W         = 32
SHIP_H         = 32
SHIP_PLANE     = (SHIP_W * SHIP_H) / 8
SHIP_SIZE      = SHIP_PLANE * PLANES

SHIPY          = SCREENY - 70
X_SPEED        = 1
Y_SPEED        = 1

TILE_W         = 16
TILE_H         = 16
TILE_PLANE     = (TILE_W * TILE_H) / 8
TILE_SIZE      = TILE_PLANE * PLANES

;----------------------------------------------------------

START:

       MOVE.L  #LEVEL_1,MAPPOINTER

       MOVE.L  EXECBASE,A6
       LEA     GFXNAME,A1
       JSR     OPENLIBRARY(A6)
       MOVE.L  D0,GFXBASE
       
       MOVE.L  #PLAYFIELD,D0
       MOVE.L  #CHIPREQUEST,D1
       JSR     ALLOCMEM(A6)
       BEQ     END_2
       MOVE.L  D0,SCREENBASE
 
       MOVE.L  #SHIP_SIZE,D0       MOVE.L  #CHIPREQUEST,D1
       JSR     ALLOCMEM(A6)
       BEQ     END_1
       MOVE.L  D0,SHIP_BUF

       MOVE.L  #PLAY,D0
       MOVE.L  #CHIPREQUEST,D1
       JSR     ALLOCMEM(A6)
       BEQ     END_0
       MOVE.L  D0,SCREEN2

       MOVE.L  #MAX_SCREEN,SCREEN_Y
       BSR     SET_SCREEN

       MOVE.L  #SHIPY,SHIP_Y
 
       BSR     CREATE_SHIP_MASK
       BSR     MONO_TASKING
       BSR     COPY_COLORS
       BSR     START_COPPER
       BSR     BUILD_BACKGROUND
       BSR     GET_BACKGROUND
       BSR     INIT_IRQ

MAIN_LOOP:

       BTST    #6,MOUSEBUTTON
       BNE.S   MAIN_LOOP

THE_END:

       BSR     EXIT_IRQ
       BSR     STOP_COPPER

END_0:
       MOVE.L  EXECBASE,A6
       MOVE.L  #PLAY,D0
       MOVE.L  SCREEN2,A1
       JSR     FREEMEM(A6)

END_1:
       MOVE.L  EXECBASE,A6
       MOVE.L  #SHIP_SIZE,D0       MOVE.L  SHIP_BUF,A1
       JSR     FREEMEM(A6)

END_2:
       MOVE.L  EXECBASE,A6
       MOVE.L  #PLAYFIELD,D0
       MOVE.L  SCREENBASE,A1
       JSR     FREEMEM(A6)

       MOVE.L  GFXBASE,A1
       JSR     CLOSELIBRARY(A6)

       BSR     MULTI_TASKING

       RTS

;----------------------------------------------------------

MONO_TASKING:

       MOVE.L  EXECBASE,A6
       JSR     FORBID(A6)
       RTS

MULTI_TASKING:

       MOVE.L  EXECBASE,A6
       JSR     PERMIT(A6)
       RTS

;----------------------------------------------------------

INIT_IRQ:

       MOVE.W  #$4000,INTENA
       MOVE.L  $6C,OLDIRQ
       MOVE.L  #NEWIRQ,$6C
       MOVE.W  #$C000,INTENA
       RTS

EXIT_IRQ:

       MOVE.W  #$4000,INTENA
       MOVE.L  OLDIRQ,$6C
       MOVE.W  #$C000,INTENA
       RTS

;----------------------------------------------------------

START_COPPER:

       MOVE.L  GFXBASE,A0
       ADD.L   #$32,A0
       MOVE.W  #$00B0,DMACON
       MOVE.L  (A0),OLDCOPPER
       MOVE.L  #NEWCOPPER,(A0)
       MOVE.W  #$8480,DMACON
       RTS

STOP_COPPER:

       MOVE.L  GFXBASE,A0
       ADD.L   #$32,A0
       MOVE.W  #$0480,DMACON
       MOVE.L  OLDCOPPER,(A0)
       MOVE.W  #$80B0,DMACON
       RTS

;----------------------------------------------------------

COPY_POINTERS:

       MOVEQ.L #4,D7

POINTER_LOOP:

       MOVE.W  D0,6(A0)
       SWAP    D0
       MOVE.W  D0,2(A0)
       SWAP    D0
       ADD.L   D1,D0
       ADDQ.L  #8,A0
       DBRA    D7,POINTER_LOOP
       RTS

;----------------------------------------------------------

JOYSTICK:

       BSR     PUT_BACKGROUND

       MOVE.W  JOY1DAT,D0
       BTST    #1,D0
       BEQ.S   JM_NOT_RIGHT
       ADDQ.L  #X_SPEED,SHIP_X
       BTST    #0,D0
       BNE.S   JOYSTICK_Y
       ADDQ.L  #Y_SPEED,SHIP_Y

JM_NOT_RIGHT:

       BTST    #0,D0
       BEQ.S   JOYSTICK_Y
       ADDQ.L  #Y_SPEED,SHIP_Y

JOYSTICK_Y:

       BTST    #9,D0
       BEQ.S   JM_NOT_LEFT
       SUBQ.L  #X_SPEED,SHIP_X
       BTST    #8,D0
       BNE.S   TST_X
       SUBQ.L  #Y_SPEED,SHIP_Y

JM_NOT_LEFT:

       BTST    #8,D0
       BEQ.S   TST_X
       SUBQ.L  #Y_SPEED,SHIP_Y

TST_X:

       MOVE.L  SHIP_X,D0
       BPL.S   NOT_NEGX
       CLR.L   SHIP_X

NOT_NEGX:

       CMP.L   #SCREENX-32,D0
       BLE.S   TST_Y
       MOVE.L  #SCREENX-32,SHIP_X

TST_Y:

  ;     MOVE.L  SHIP_Y,D0
  ;     BPL.S   NOT_NEGY
  ;     CLR.L   SHIP_Y

NOT_NEGY:

   ;    CMP.L   #MAX_Y,D0
   ;    BLE     NOT_MOREY
   ;    MOVE.L  #MAX_Y,SHIP_Y

NOT_MOREY:

       BSR     GET_BACKGROUND

       RTS

;----------------------------------------------------------

SET_SCREEN:

       CLR.L   D0
       CLR.L   D2
       MOVE.L  SCREEN_Y(PC),D1
       BSR     CALC_POS

       ADD.L   SCREENBASE,D0
       ADD.L   D2,D0
       LEA     COPPER2,A0
       MOVE.L  #PLANESIZE,D1
       BSR     COPY_POINTERS
       RTS

;----------------------------------------------------------

COPY_COLORS:

       LEA     COLORTAB(PC),A0
       LEA     COPPER3,A1
       MOVEQ.L #31,D7
       MOVE.L  #$180,D0

COLOR_LOOP:

       MOVE.W  D0,(A1)+
       MOVE.W  (A0)+,(A1)+
       ADDQ.L  #2,D0
       DBRA    D7,COLOR_LOOP
       RTS

;----------------------------------------------------------

WAIT_BLIT:
       TST     DMACONR
LOCAL_WAIT_BLIT:
       BTST    #14,DMACONR
       BNE.S   LOCAL_WAIT_BLIT
       RTS

;----------------------------------------------------------

CALC_POS:

       MOVE.W  D1,D2
       MOVE.W  D0,D1
       LSR.W   #4,D0
       LSL.W   #1,D0
       AND.W   #$000F,D1
       MULU    #SCREENB,D2
       LSL.W   #8,D1
       LSL.W   #4,D1
       MOVE.W  D1,CONTROL
       RTS

;----------------------------------------------------------

BUILD_BACKGROUND:

       MOVEQ   #(SCREENY / TILE_H) - 1,D5

Y_LOOP:

       BSR.S   SETCHAR
       ADD.L   #TILE_H,GROUND_Y
       DBRA    D5,Y_LOOP
       RTS

SETCHAR:

       CMP.L   #MAPCHARS,MAPZAEHLER
       BHI.S   RESET_MAP
       BSR.S   SET_ROW
       RTS

RESET_MAP:

       MOVE.L  #LEVEL_1,MAPPOINTER
       CLR.L   MAPZAEHLER
       BRA.S   SETCHAR

SET_ROW:

       MOVEQ   #(SCREENB / 2) - 1,D6

ROW_LOOP:

       BSR     CALC_ADRESS

       BSR     BLITBACKGROUND

       ADD.L   #TILE_W,GROUND_X
       ADDQ.L  #1,MAPPOINTER
       ADDQ.L  #1,MAPZAEHLER

       DBRA    D6,ROW_LOOP

       CLR.L   GROUND_X
       RTS

CALC_ADRESS:

       CLR.L   D0
       MOVE.L  #TILE_SIZE,D1

       MOVE.L  MAPPOINTER(PC),A0
       MOVE.B  (A0),D0
       MULU    D0,D1

       MOVE.L  #GROUND_DATA,D0
       ADD.L   D1,D0
       MOVE.L  D0,DATA_POINTER
       RTS

;----------------------------------------------------------

BLITBACKGROUND:

       MOVEQ   #0,D2
       MOVE.L  GROUND_X(PC),D0
       MOVE.L  GROUND_Y(PC),D1
       BSR     CALC_POS

       ADD.L   SCREENBASE(PC),D0
       ADD.L   D2,D0

       MOVE.L  DATA_POINTER(PC),D1

       BSR     WAIT_BLIT

       MOVE.W #0,BLTCON1       MOVE.W  CONTROL,D2
       ADD.W   #$09F0,D2
       MOVE.W  D2,BLTCON0
 
       MOVE.L  #$FFFFFFFF,BLTAFWM

       MOVE.W  #0,BLTAMOD
       MOVE.W  #SCREENB-2,BLTDMOD

       MOVEQ   #PLANES-1,D7

BACK_LOOP:

       MOVE.L  D0,BLTDPTH
       MOVE.L  D1,BLTAPTH

       MOVE.W  #$0401,BLTSIZE

       ADD.L   #PLANESIZE,D0
       ADD.L   #TILE_PLANE,D1

       BSR     WAIT_BLIT

       DBRA    D7,BACK_LOOP
       RTS

;----------------------------------------------------------

BLAU_CYCLE:

       MOVEQ.L #6,D6
       LEA     BLAU1(PC),A0
       BSR.S   COLOR_CYCLE

       BRA     IRQ1
COLOR_CYCLE:

       MOVE.W  (A0),D0
       MOVE.L  A0,A1

CYCLE_LOOP:

       MOVE.W  2(A0),DUMMY
       MOVE.W  D0,2(A0)
       MOVE.W  DUMMY(PC),D0
       ADDQ.L  #2,A0
       DBRA    D6,CYCLE_LOOP
       MOVE.W  DUMMY(PC),(A1)
       BSR     COPY_COLORS
       CLR.W   COLOR_ZAEHLER
       RTS

;----------------------------------------------------------

GET_BACKGROUND:

       MOVEQ.L #PLANES-1,D7

       MOVE.L  SHIP_X(PC),D0
       MOVE.L  SHIP_Y(PC),D1
       BSR     CALC_POS

       ADD.L   SCREENBASE(PC),D0
       ADD.L   D2,D0

       MOVE.L  SHIP_BUF(PC),D1

       BSR     WAIT_BLIT

       MOVE.W  #0,BLTCON1
       MOVE.W  #$09F0,BLTCON0

       MOVE.L  #$FFFFFFFF,BLTAFWM

       MOVE.W  #SCREENB-4,BLTAMOD
       MOVE.W  #0,BLTDMOD

   
BACK_1:

       MOVE.L  D0,BLTAPTH
       MOVE.L  D1,BLTDPTH

       MOVE.W  #$0802,BLTSIZE

       ADD.L   #PLANESIZE,D0
       ADD.L   #SHIP_PLANE,D1
       BSR     WAIT_BLIT

       DBRA    D7,BACK_1

PUT_SHIP:

       MOVEQ.L #PLANES-1,D7

       MOVE.L  SHIP_X,D0
       MOVE.L  SHIP_Y,D1
       BSR     CALC_POS

       ADD.L   SCREENBASE(PC),D0
       ADD.L   D2,D0

       MOVE.L  D0,D3

       MOVE.L  #SHIP_DATA,D1
       MOVE.L  #SHIP_MASK,D0
       MOVE.L  SHIP_BUF,D2

       BSR     WAIT_BLIT

       MOVE.W  CONTROL(PC),D4
       MOVE.W  D4,BLTCON1
       ADD.W   #$0FCA,D4
       MOVE.W  D4,BLTCON0

       MOVE.W  #0,BLTAMOD
       MOVE.W  #0,BLTBMOD
       MOVE.W  #0,BLTCMOD
       MOVE.W  #SCREENB-4,BLTDMOD

PUT_LOOP:

       MOVE.L  D0,BLTAPTH
       MOVE.L  D1,BLTBPTH
       MOVE.L  D2,BLTCPTH
       MOVE.L  D3,BLTDPTH

       MOVE.W  #$0802,BLTSIZE

       ADD.L   #SHIP_PLANE,D1       ADD.L   #SHIP_PLANE,D2
       ADD.L   #PLANESIZE,D3

       BSR     WAIT_BLIT

       DBRA    D7,PUT_LOOP

KOLLISION:

       MOVE.W  CONTROL(PC),BLTCON1
       MOVE.W  #$0CC0,BLTCON0

       MOVE.W  #0,BLTAMOD
       MOVE.W  #0,BLTBMOD

       MOVE.L  #SHIP_MASK,BLTBPTH
;       ADD.L   #SHIP_PLANE*4,D0
;       MOVE.L  D0,BLTAPTH

       MOVE.L  SHIP_BUF,D0
       ADD.L   #SHIP_SIZE-SHIP_PLANE,D0
       MOVE.L  D0,BLTAPTH
 
       MOVE.W  #$0802,BLTSIZE

       BSR     WAIT_BLIT
       BTST    #13,DMACONR
       BEQ.S   HANDLE_COLLISION

       RTS

;---------------------------------------------------------

HANDLE_COLLISION:

       MOVE.W  #$888,$DFF180 ; Just make the background grey for now.
       RTS

;----------------------------------------------------------

PUT_BACKGROUND:

       MOVEQ   #PLANES-1,D7

       MOVE.L  SHIP_X,D0
       MOVE.L  SHIP_Y,D1
       BSR     CALC_POS

       ADD.L   SCREENBASE,D0
       ADD.L   D2,D0

       MOVE.L  SHIP_BUF,D1

       BSR     WAIT_BLIT

       MOVE.W  #0,BLTCON1
       MOVE.W  #$09F0,BLTCON0

       MOVE.W  #0,BLTAMOD
       MOVE.W  #SCREENB-4,BLTDMOD

BACK_2:

       MOVE.L  D1,BLTAPTH
       MOVE.L  D0,BLTDPTH
       MOVE.W  #$0802,BLTSIZE

       ADD.L   #PLANESIZE,D0
       ADD.L   #SHIP_PLANE,D1
       BSR     WAIT_BLIT

       DBRA    D7,BACK_2

       RTS

;----------------------------------------------------------

CREATE_SHIP_MASK:

       LEA     SHIP_DATA,A0
       LEA     SHIP_MASK,A1
       MOVEQ.L #SHIP_H-1,D7
FIRST_LOOP:

       MOVE.L  SHIP_PLANE*0(A0),D0       OR.L    SHIP_PLANE*1(A0),D0       OR.L    SHIP_PLANE*2(A0),D0       OR.L    SHIP_PLANE*3(A0),D0       OR.L    SHIP_PLANE*4(A0),D0       MOVE.L  D0,(A1)+

       ADDQ.L  #4,A0
       DBRA    D7,FIRST_LOOP
       RTS

;----------------------------------------------------------

SCREEN_BACK:

       MOVE.L  #MAX_SCREEN,SCREEN_Y
       BSR     SET_SCREEN
       BSR     PUT_BACKGROUND
       ADD.L   #MAX_SCREEN,SHIP_Y
       BSR     GET_BACKGROUND
       BRA     IRQ2

;----------------------------------------------------------

NEWCOPPER:

       DC.W    $008E,$2CB1     ; DIWSTART
       DC.W    $0090,$2C91     ; DIWSTOP
       DC.W    $0092,$0050     ; DDFSTART
       DC.W    $0094,$00B8     ; DFFSTOP
       DC.W    $0100,$5200     ; 5 BITPLANES

       DC.W    $0108,$0000     ; MODULO 1
       DC.W    $010A,$0000     ; MODULO 2

COPPER2:

       DC.W    $00E0,0         ; BITPLANE 1
       DC.W    $00E2,0
       DC.W    $00E4,0         ; BITPLANE 2
       DC.W    $00E6,0
       DC.W    $00E8,0         ; BITPLANE 3
       DC.W    $00EA,0
       DC.W    $00EC,0         ; BITPLANE 4
       DC.W    $00EE,0
       DC.W    $00F0,0         ; BITPLANE 5
       DC.W    $00F2,0

COPPER3:

       DS.B    128,0           ; PLATZ FÜR DIE FARBTABELLE

       DC.W    $FFFF,$FFFE     ; COPPERLIST ENDE

;----------------------------------------------------------

NEWIRQ:

       MOVEM.L D0-D7/A0-A6,-(A7)

       CMP.L   #MIN_SCREEN,SCREEN_Y
       BEQ     SCREEN_BACK

IRQ2:  SUBQ.L  #SCROLL_SPEED,SCREEN_Y
       BSR     SET_SCREEN
       BSR     PUT_BACKGROUND
       SUBQ.L  #SCROLL_SPEED,SHIP_Y
       BSR     GET_BACKGROUND

       CMP.W   #2,COLOR_ZAEHLER
       BEQ     BLAU_CYCLE

IRQ1:

       BSR     JOYSTICK

       ADDQ.W  #1,COLOR_ZAEHLER

       MOVEM.L (A7)+,D0-D7/A0-A6
       DC.W    $4EF9

OLDIRQ:        DC.L    0 ; Self modifying code is the root of all evil!
;----------------------------------------------------------

SCREENBASE:    DC.L    0
SCREEN2:       DC.L    0
GFXBASE:       DC.L    0
OLDCOPPER:     DC.L    0

SCREEN_Y:      DC.L    0
SHIP_Y:        DC.L    0
SHIP_X:        DC.L    32

GROUND_X:      DC.L    0
GROUND_Y:      DC.L    0

DATA_POINTER:  DC.L    0

MAPPOINTER:    DC.L    0
MAPZAEHLER:    DC.L    0

SHIP_BUF:      DC.L    0

CONTROL:       DC.W    0
COLOR_ZAEHLER: DC.W    0
DUMMY:         DC.W    0

COLORTAB:
               DC.W    $000,$ECA,$222,$446,$668,$99B,$CCE,$EEF
BLAU1:         DC.W    $3AC,$19B,$079,$079,$189,$29B,$3BD,$5CE
               DC.W    $ED0,$CA1,$D82,$C73,$951,$740,$2B0,$1A0
               DC.W    $190,$180,$070,$060,$F20,$D20,$B20,$920
 ALIGN.L
LEVEL_1:
              IBYTES   "LEVEL/LEVEL1.MAP"
LEVEL_1_END:

GFXNAME:       DC.B    "graphics.library",0
     
 ALIGN.L
GROUND_DATA:

               DS.B    TILE_SIZE,0          ; 0
               IBYTES  "BITS/WASSER1.BIT"   ; 1               IBYTES  "BITS/WASSER2.BIT"   ; 2               IBYTES  "BITS/WASSER3.BIT"   ; 3               IBYTES  "BITS/WASSER4.BIT"   ; 4               IBYTES  "BITS/WASSER5.BIT"   ; 5               IBYTES  "BITS/WASSER6.BIT"   ; 6               IBYTES  "BITS/UFER1.BIT"     ; 7               IBYTES  "BITS/UFER2.BIT"     ; 8               IBYTES  "BITS/UFER3.BIT"     ; 9               IBYTES  "BITS/UFER4.BIT"     ; 10               IBYTES  "BITS/ROCK1.BIT"     ; 11               IBYTES  "BITS/ROCK2.BIT"     ; 12               IBYTES  "BITS/BOJE1.BIT"     ; 13               IBYTES  "BITS/BOJE2.BIT"     ; 14               IBYTES  "BITS/BRUECKE1.BIT"  ; 15               IBYTES  "BITS/BRUECKE2.BIT"  ; 16               IBYTES  "BITS/BRUECKE3.BIT"  ; 17               IBYTES  "BITS/KURVE1.BIT"    ; 18               IBYTES  "BITS/KURVE2.BIT"    ; 19               IBYTES  "BITS/KURVE3.BIT"    ; 20               IBYTES  "BITS/KURVE4.BIT"    ; 21               IBYTES  "BITS/LAND1.BIT"     ; 22               IBYTES  "BITS/BUCHT1.BIT"    ; 23               IBYTES  "BITS/BUCHT2.BIT"    ; 24               IBYTES  "BITS/BUCHT3.BIT"    ; 25               IBYTES  "BITS/BUCHT4.BIT"    ; 26               IBYTES  "BITS/GRAS1.BIT"     ; 27               IBYTES  "BITS/GRAS2.BIT"     ; 28               IBYTES  "BITS/GRAS3.BIT"     ; 29               IBYTES  "BITS/GRAS4.BIT"     ; 30               IBYTES  "BITS/GRAS5.BIT"     ; 31               IBYTES  "BITS/PALME1.BIT"    ; 32               IBYTES  "BITS/PALME2.BIT"    ; 33               IBYTES  "BITS/PALME3.BIT"    ; 34               IBYTES  "BITS/PALME4.BIT"    ; 35               IBYTES  "BITS/SAND1.BIT"     ; 36               IBYTES  "BITS/SAND2.BIT"     ; 37               IBYTES  "BITS/SAND3.BIT"     ; 38               IBYTES  "BITS/SAND4.BIT"     ; 39

SHIP_DATA:
               IBYTES  "BITS/SHIP.BIT"

SHIP_MASK:     DS.B    SHIP_PLANE,0 END


