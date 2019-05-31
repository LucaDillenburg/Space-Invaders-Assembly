include \masm32\include\windows.inc

include \masm32\include\masm32.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\msimg32.inc

includelib \masm32\lib\masm32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\msimg32.lib

;=================
; structs
;=================

invader struct
    x       dd ?
    y       dd ?
    alive   db 1
invader ends

balloonStruct struct
    x     dd ?
    y     dd ?
    speed dd 0
    max   dd ?
    side  dd ?
    alive db 0
balloonStruct ends

shipStruct struct
    x       dd ?
    y       dd ?
    w       dd 30
    h       dd 20
    lives   db 3
    points  dd 0
shipStruct ends

bulletStInv struct
    x       dd ?
    y       dd ?
    exists  db 0
bulletStInv ends

bulletStruct struct
    x       dd ?
    y       dd ?
    w       dd 6
    h       dd 16
    exists  db 0
bulletStruct ends

numberStruct struct
    n1 dd 0
    n2 dd 0
    n3 dd 0
    n4 dd 0
    n5 dd 0
numberStruct ends

;node struct ;Nó de uma lista ligada
;    next dd ?
;    value gameObj <>
;node ends

;=================
; const
;=================
.const
    imgInvaders equ 100
    imgAircraft equ 101
    imgBarrier  equ 102
    imgGround   equ 103
    imgTitle_g  equ 104
    imgBullet   equ 105
    imgIntro1   equ 106
    imgIntro2   equ 107
    imgBalloon  equ 108

    imgNumber0  equ 109
    imgNumber1  equ 110
    imgNumber2  equ 111
    imgNumber3  equ 112
    imgNumber4  equ 113
    imgNumber5  equ 114
    imgNumber6  equ 115
    imgNumber7  equ 116
    imgNumber8  equ 117
    imgNumber9  equ 118

    WM_MOVEMENT equ WM_USER+100h
    WM_BULLET equ WM_USER+101h
    WM_BALLOON equ WM_USER+102h

	CREF_TRANSPARENT  equ 0FF00FFh
	CREF_TRANSPARENT2 equ 0FF0000h

    INVADER_SIZE equ 9

    INITIAL_Y_BULLET equ 368
    INITIAL_Y_SHIP   equ 387

    AMOUNT_INVADERS equ 36
    INVADERS_PER_LINE equ 6

    AMOUNT_SHIP_MOVES equ 6
    LEFT_LIMITATOR equ 136
    RIGHT_LIMITATOR equ 466

    AMOUNT_INVADERS_MOVE_X   equ 4
    AMOUNT_INVADERS_MOVE_Y   equ 20
    LEFT_LIMITATOR_INVADERS  equ 81
    RIGHT_LIMITATOR_INVADERS equ 449

    posXFirst equ 81
    posYFirst equ 79

    spaceBetweenInvaders equ 32
    spaceBetweenLines    equ 16

    WIDTH_INVADER equ 34
    HEIGHT_INVADER equ 20

    NOT_MOVING equ 0
    MOVING_LEFT equ 1
    MOVING_RIGHT equ 2

    ; Left side
    BALLOON_LEFT_X equ -20
    BALLOON_LEFT_MAX_X equ 650

    ;Right side
    BALLOON_RIGHT_X equ 640
    BALLOON_RIGHT_MAX_X equ -30

    ; Common y
    BALLOON_START_Y equ 10
    BALLOON_SPEED equ 5

    MILISECONDS_MAIN_THREAD equ 25 ; tempo de intervalo da thread principal
    PROPORC_THREAD_MOVE_BULLET equ 1
    PROPORC_THREAD_MOVE_BALLOON equ 5
    PROPORC_THREAD_MOVE_INVADERS equ 20

    LINE_1_POINTS equ 30
    LINE_2_POINTS equ 25
    LINE_3_POINTS equ 20
    LINE_4_POINTS equ 15
    LINE_5_POINTS equ 10
    LINE_6_POINTS equ 5

    BALLOON_POINTS equ 500

;=================
; data
;=================
.data


.data?

;=================
; prototypes
;=================
LoadAssets PROTO
WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
TopXY PROTO   :DWORD,:DWORD
Paint_Proc	PROTO :DWORD, :DWORD

MainThreadProc PROTO :DWORD
