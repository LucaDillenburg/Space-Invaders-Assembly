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
    alive    db 1
invader ends

shipStruct struct
    x       dd ?
    y       dd ?
    w       dd 30
    h       dd 20
    lives   db 5
shipStruct ends

bulletStruct struct
    x       dd ?
    y       dd ?
    w       dd 6
    h       dd 16
    exists  db 0
bulletStruct ends

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

    WM_MOVEMENT equ WM_USER+100h
    WM_BULLET equ WM_USER+101h

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

    AMOUNT_INVADERS_MOVE_X   equ 1;20
    AMOUNT_INVADERS_MOVE_Y   equ 0 ;30
    LEFT_LIMITATOR_INVADERS  equ 120
    RIGHT_LIMITATOR_INVADERS equ 480

    posYFirst            equ 70
    posXFirst            equ LEFT_LIMITATOR_INVADERS
    spaceBetweenInvaders equ 45
    spaceBetweenLines    equ 70

    WIDTH_INVADER equ 34
    HEIGHT_INVADER equ 20


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

ThreadProcInvaders PROTO :DWORD
ThreadProcBullet   PROTO :DWORD