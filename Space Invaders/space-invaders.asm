; #########################################################################
;
;             GENERIC.ASM is a roadmap around a standard 32 bit 
;              windows application skeleton written in MASM32.
;
; #########################################################################
;
;           Assembler specific instructions for 32 bit ASM code

      .386                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive

; #########################################################################

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc

      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------
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

; #########################################################################

;
; @authors 17184 --> Iuri Guimarães Slywitch
;          17188 --> Luca Assumpção Dillenburg
;          17162 --> André Amadeu Satorres
;



; ------------------------------------------------------------------------
; MACROS are a method of expanding text at assembly time. This allows the
; programmer a tidy and convenient way of using COMMON blocks of code with
; the capacity to use DIFFERENT parameters in each block.
; ------------------------------------------------------------------------

      ; 1. szText
      ; A macro to insert TEXT into the code section for convenient and 
      ; more intuitive coding of functions that use byte data as text.

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      ; 2. m2m
      ; There is no mnemonic to copy from one memory location to another,
      ; this macro saves repeated coding of this process and is easier to
      ; read in complex code.

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      ; 3. return
      ; Every procedure MUST have a "ret" to return the instruction
      ; pointer EIP back to the next instruction after the call that
      ; branched to it. This macro puts a return value in eax and
      ; makes the "ret" instruction on one line. It is mainly used
      ; for clear coding in complex conditionals in large branching
      ; code such as the WndProc procedure.

      return MACRO arg
        mov eax, arg
        ret
      ENDM

; #########################################################################

; ----------------------------------------------------------------------
; Prototypes are used in conjunction with the MASM "invoke" syntax for
; checking the number and size of parameters passed to a procedure. This
; improves the reliability of code that is written where errors in
; parameters are caught and displayed at assembly time.
; ----------------------------------------------------------------------

        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
        
        Paint_Proc	PROTO :DWORD, :DWORD

; #########################################################################


; definindo as constantes
.Const
	invaders equ 100
    aircraft equ 101
    barrier  equ 102
    ground   equ 103
    title_g  equ 104
    bullet   equ 105

    WM_MOVEMENT equ WM_USER+100h
    WM_BULLET equ WM_USER+101h

	CREF_TRANSPARENT  EQU 0FF00FFh
	CREF_TRANSPARENT2 EQU 0FF0000h

; ------------------------------------------------------------------------
; This is the INITIALISED data section meaning that data declared here has
; an initial value. You can also use an UNINIALISED section if you need
; data of that type [ .data? ]. Note that they are different and occur in
; different sections.
; ------------------------------------------------------------------------

    .data
        szDisplayName db "Space Invaders v1.0",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0

        ThreadID dd 0
        hThread dd 0
        threadControl dd 0
	    hEventStart  dd 0
        hEventStart1 dd 0

	    hBmpInvaders dd 0
        hBmpAircraft dd 0
        hBmpBarrier  dd 0
        hBmpGround   dd 0
        hBmpTitle    dd 0
        hBmpBullet   dd 0

        invert db 0
        direction db 0

        posC1 dd 81
        posC2 dd 147
        posC3 dd 209
        posC4 dd 273
        posC5 dd 337
        posC6 dd 401

        posR1 dd 79
        posR2 dd 115
        posR3 dd 151
        posR4 dd 187
        posR5 dd 223
        posR6 dd 259

        I1 dd 0
        I2 dd 40
        I3 dd 80
        I4 dd 120
        I5 dd 160
        I6 dd 200

        shipX dd 136
        shipY dd 387

        bulletX dd 0
        bulletY dd 368

; #########################################################################

; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------

    .code

; -----------------------------------------------------------------------
; The label "start:" is the address of the start of the code section and
; it has a matching "end start" at the end of the file. All procedures in
; this module must be written between these two.
; -----------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax
    
    invoke LoadBitmap, hInstance, invaders
    mov	hBmpInvaders, eax

    invoke LoadBitmap, hInstance, aircraft
    mov hBmpAircraft, eax

    invoke LoadBitmap, hInstance, barrier
    mov hBmpBarrier, eax

    invoke LoadBitmap, hInstance, ground
    mov hBmpGround, eax

    invoke LoadBitmap, hInstance, title_g
    mov hBmpTitle, eax

    invoke LoadBitmap, hInstance, bullet
    mov hBmpBullet, eax

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Primeiro_Class"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+4     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
        invoke LoadIcon, hInst, 500 ; icon ID ; resource icon
        mov wc.hIcon,          eax
        invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

        ;================================
        ; Centre window at following size
        ;================================

        mov Wwd, 650
        mov Wht, 500

        invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
        invoke TopXY,Wwd,eax
        mov Wtx, eax

        invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
        invoke TopXY,Wht,eax
        mov Wty, eax

        ; ==================================
        ; Create the main application window
        ; ==================================
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR szDisplayName,
                              WS_OVERLAPPEDWINDOW,
                              Wtx,Wty,Wwd,Wht,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

	LOCAL Ps 	:PAINTSTRUCT
	LOCAL hDC	:DWORD  ; handle do dispositivo (tela)

; -------------------------------------------------------------------------
; Message are sent by the operating system to an application through the
; WndProc proc. Each message can have additional values associated with it
; in the two parameters, wParam & lParam. The range of additional data that
; can be passed to an application is determined by the message.
; -------------------------------------------------------------------------

    .if uMsg == WM_COMMAND
    ;----------------------------------------------------------------------
    ; The WM_COMMAND message is sent by menus, buttons and toolbar buttons.
    ; Processing the wParam parameter of it is the method of obtaining the
    ; control's ID number so that the code for each operation can be
    ; processed. NOTE that the ID number is in the LOWORD of the wParam
    ; passed with the WM_COMMAND message. There may be some instances where
    ; an application needs to seperate the high and low words of wParam.
    ; ---------------------------------------------------------------------
    
    .elseif uMsg == WM_PAINT

	invoke BeginPaint, hWin, ADDR Ps
	mov	hDC, eax
	
	invoke  Paint_Proc, hWin, hDC
	
	invoke EndPaint, hWin, ADDR Ps


    .elseif uMsg == WM_CREATE
    ; --------------------------------------------------------------------
    ; This message is sent to WndProc during the CreateWindowEx function
    ; call and is processed before it returns. This is used as a position
    ; to start other items such as controls. IMPORTANT, the handle for the
    ; CreateWindowEx call in the WinMain does not yet exist so the HANDLE
    ; passed to the WndProc [ hWin ] must be used here for any controls
    ; or child windows.
    ; --------------------------------------------------------------------
    invoke CreateEvent, NULL, FALSE, FALSE, NULL

	mov hEventStart, eax
		
	mov eax, OFFSET ThreadProc

	invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID

    inc ThreadID

	mov    hThread, eax

    .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_LEFT
          .if shipX != 136
            sub shipX, 6
          .endif
        .elseif wParam == VK_RIGHT
          .if shipX != 466
            add shipX, 6
          .endif
        .elseif wParam == VK_SPACE
          invoke CreateEvent, NULL, FALSE, FALSE, NULL
	      mov hEventStart1, eax
          mov  eax, OFFSET ThreadProc1
		  invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID
          mov threadControl, eax
          invoke CloseHandle, eax
        .elseif wParam == VK_RETURN
          rdtsc
          mov bx, 6
          div bx
          inc dx
          add shipY, dx
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_MOVEMENT
        .if direction == 0
          .if posC6 == 513
            mov direction, 1
            add posR1, 20
            add posR2, 20
            add posR3, 20
            add posR4, 20
            add posR5, 20
            add posR6, 20
          .else
            add posC1, 4
            add posC2, 4
            add posC3, 4
            add posC4, 4
            add posC5, 4 
            add posC6, 4
          .endif
          
        .elseif direction == 1
          .if posC1 == 81
            mov direction, 0
            add posR1, 20
            add posR2, 20
            add posR3, 20
            add posR4, 20
            add posR5, 20
            add posR6, 20
          .else
            sub posC1, 4
            sub posC2, 4
            sub posC3, 4
            sub posC4, 4
            sub posC5, 4
            sub posC6, 4
          .endif
        .endif

        .if invert == 0
          mov invert, 1
          add I1, 20
          add I2, 20
          add I3, 20
          add I4, 20
          add I5, 20
          add I6, 20
        .elseif invert == 1
          mov invert, 0
          sub I1, 20
          sub I2, 20
          sub I3, 20
          sub I4, 20
          sub I5, 20
          sub I6, 20
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_BULLET

        .if bulletY == 368
          ;Adicionando posicao inicial da bala
          mov eax, shipX
          add eax, 12
          mov bulletX, eax

          sub bulletY, 4

        .elseif bulletY != 0
          sub bulletY, 4
        .elseif bulletY == 0
          mov bulletX, 0
          mov bulletY, 368
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_CLOSE
    ; -------------------------------------------------------------------
    ; This is the place where various requirements are performed before
    ; the application exits to the operating system such as deleting
    ; resources and testing if files have been saved. You have the option
    ; of returning ZERO if you don't wish the application to close which
    ; exits the WndProc procedure without passing this message to the
    ; default window processing done by the operating system.
    ; -------------------------------------------------------------------

    .elseif uMsg == WM_DESTROY
    ; ----------------------------------------------------------------
    ; This message MUST be processed to cleanly exit the application.
    ; Calling the PostQuitMessage() function makes the GetMessage()
    ; function in the WinMain() main loop return ZERO which exits the
    ; application correctly. If this message is not processed properly
    ; the window disappears but the code is left in memory.
    ; ----------------------------------------------------------------
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ; --------------------------------------------------------------------
    ; Default window processing is done by the operating system for any
    ; message that is not processed by the application in the WndProc
    ; procedure. If the application requires other than default processing
    ; it executes the code when the message is trapped and returns ZERO
    ; to exit the WndProc procedure before the default window processing
    ; occurs with the call to DefWindowProc().
    ; --------------------------------------------------------------------

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; ########################################################################


Paint_Proc proc hWin:DWORD, hDC:DWORD

	LOCAL hOld:DWORD
	LOCAL memDC:DWORD

	invoke  CreateCompatibleDC, hDC
	mov	memDC, eax

    ;invoke SelectObject, memDC, hBmpTitle
	;mov	hOld, eax

    ;invoke BitBlt, hDC, 127, 0, 300, 19, memDC, 0, 0, SRCCOPY
    
    invoke SelectObject, memDC, hBmpInvaders
	mov	hOld, eax
	
    ; First invaders.
	invoke BitBlt, hDC, posC1, posR1, 34, 20, memDC, 0, I1, SRCCOPY
    invoke BitBlt, hDC, posC2, posR1, 34, 20, memDC, 0, I1, SRCCOPY
    invoke BitBlt, hDC, posC3, posR1, 34, 20, memDC, 0, I1, SRCCOPY
    invoke BitBlt, hDC, posC4, posR1, 34, 20, memDC, 0, I1, SRCCOPY
    invoke BitBlt, hDC, posC5, posR1, 34, 20, memDC, 0, I1, SRCCOPY
    invoke BitBlt, hDC, posC6, posR1, 34, 20, memDC, 0, I1, SRCCOPY

    ; Second invaders.
	invoke BitBlt, hDC, posC1, posR2, 34, 20, memDC, 0, I2, SRCCOPY
    invoke BitBlt, hDC, posC2, posR2, 34, 20, memDC, 0, I2, SRCCOPY
    invoke BitBlt, hDC, posC3, posR2, 34, 20, memDC, 0, I2, SRCCOPY
    invoke BitBlt, hDC, posC4, posR2, 34, 20, memDC, 0, I2, SRCCOPY
    invoke BitBlt, hDC, posC5, posR2, 34, 20, memDC, 0, I2, SRCCOPY
    invoke BitBlt, hDC, posC6, posR2, 34, 20, memDC, 0, I2, SRCCOPY

    ; Third invaders.
	invoke BitBlt, hDC, posC1, posR3, 34, 20, memDC, 0, I3, SRCCOPY
    invoke BitBlt, hDC, posC2, posR3, 34, 20, memDC, 0, I3, SRCCOPY
    invoke BitBlt, hDC, posC3, posR3, 34, 20, memDC, 0, I3, SRCCOPY
    invoke BitBlt, hDC, posC4, posR3, 34, 20, memDC, 0, I3, SRCCOPY
    invoke BitBlt, hDC, posC5, posR3, 34, 20, memDC, 0, I3, SRCCOPY
    invoke BitBlt, hDC, posC6, posR3, 34, 20, memDC, 0, I3, SRCCOPY

    ; Fourth invaders.
	invoke BitBlt, hDC, posC1, posR4, 34, 20, memDC, 0, I4, SRCCOPY
    invoke BitBlt, hDC, posC2, posR4, 34, 20, memDC, 0, I4, SRCCOPY
    invoke BitBlt, hDC, posC3, posR4, 34, 20, memDC, 0, I4, SRCCOPY
    invoke BitBlt, hDC, posC4, posR4, 34, 20, memDC, 0, I4, SRCCOPY
    invoke BitBlt, hDC, posC5, posR4, 34, 20, memDC, 0, I4, SRCCOPY
    invoke BitBlt, hDC, posC6, posR4, 34, 20, memDC, 0, I4, SRCCOPY

    ; Fifth invaders.
	invoke BitBlt, hDC, posC1, posR5, 34, 20, memDC, 0, I5, SRCCOPY
    invoke BitBlt, hDC, posC2, posR5, 34, 20, memDC, 0, I5, SRCCOPY
    invoke BitBlt, hDC, posC3, posR5, 34, 20, memDC, 0, I5, SRCCOPY
    invoke BitBlt, hDC, posC4, posR5, 34, 20, memDC, 0, I5, SRCCOPY
    invoke BitBlt, hDC, posC5, posR5, 34, 20, memDC, 0, I5, SRCCOPY
    invoke BitBlt, hDC, posC6, posR5, 34, 20, memDC, 0, I5, SRCCOPY

    ; Sixth invaders.
	invoke BitBlt, hDC, posC1, posR6, 34, 20, memDC, 0, I6, SRCCOPY
    invoke BitBlt, hDC, posC2, posR6, 34, 20, memDC, 0, I6, SRCCOPY
    invoke BitBlt, hDC, posC3, posR6, 34, 20, memDC, 0, I6, SRCCOPY
    invoke BitBlt, hDC, posC4, posR6, 34, 20, memDC, 0, I6, SRCCOPY
    invoke BitBlt, hDC, posC5, posR6, 34, 20, memDC, 0, I6, SRCCOPY
    invoke BitBlt, hDC, posC6, posR6, 34, 20, memDC, 0, I6, SRCCOPY

    invoke SelectObject, memDC, hBmpAircraft
    mov hOld, eax

    invoke BitBlt, hDC, shipX, shipY, 30, 20, memDC, 0, 0, SRCCOPY

    invoke SelectObject, memDC, hBmpBarrier
    mov hOld, eax

    invoke BitBlt, hDC, 200, 331, 34, 36, memDC, 0, 0, SRCCOPY
    invoke BitBlt, hDC, 294, 331, 34, 36, memDC, 0, 0, SRCCOPY
    invoke BitBlt, hDC, 388, 331, 34, 36, memDC, 0, 0, SRCCOPY

    invoke SelectObject, memDC, hBmpGround
    mov hOld, eax

    invoke BitBlt, hDC, 0, 409, 630, 49, memDC, 0, 0, SRCCOPY

    .if bulletX != 0
      invoke SelectObject, memDC, hBmpBullet
      mov hOld, eax
      invoke BitBlt, hDC, bulletX, bulletY, 6, 16, memDC, 0, 0, SRCCOPY
    .endif
	
	invoke SelectObject, hDC, hOld
	invoke DeleteDC, memDC

	return 0
Paint_Proc endp

ThreadProc PROC USES ecx Param:DWORD
    invoke WaitForSingleObject, hEventStart, 500

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_MOVEMENT, NULL, NULL
        ; Aqui deve-se programar a saida da thread quando acabar o jogo.
        jmp ThreadProc
    .endif

    ret
ThreadProc ENDP

ThreadProc1 PROC USES ecx Param:DWORD
    invoke WaitForSingleObject, hEventStart1, 30

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_BULLET, NULL, NULL
        .if bulletY != 0
          jmp ThreadProc1
        .endif
        invoke ExitThread, threadControl
    .endif

ret
ThreadProc1 ENDP

end start