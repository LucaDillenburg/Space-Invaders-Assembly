.386                   ; minimum processor needed for 32 bit
.model flat, stdcall   ; FLAT memory model & STDCALL calling
option casemap :none   ; set code to case sensitive

include space-invaders.inc

;
; @authors 17184 --> Iuri Guimarães Slywitch
;          17188 --> Luca Assumpção Dillenburg
;          17162 --> André Amadeu Satorres
;

; ARRUMAR TIRO INVADERS
; Falta os invaders acelerarem com a medida de que eles vao sendo destruidos.
; Setar o maximo x para as fileiras tambem para que eles percorram todos os lados.
; Fazer colisao com barreira
; Arrumar o restart
; Fazer a pontuacao

; Comando para parar thread da bala.
; invoke ExitThread, threadControl

; ###################   MACROS   ###################

    ; 1. szText
    szText MACRO Name, Text:VARARG
    LOCAL lbl
        jmp lbl
        Name db Text,0
        lbl:
    ENDM

    ; 2. m2m (memory to memory: tipo mov)
    m2m MACRO M1, M2
    push M2
    pop  M1
    ENDM

    ; 3. return (ret, mas em eax)
    return MACRO arg
    mov eax, arg
    ret
    ENDM

.data
    buffer1          db 256 dup(?)
    header_format1   db "eax : %d",0

; outros
    szDisplayName db "Space Invaders v1.0",0
    CommandLine   dd 0
    hWnd          dd 0
    hInstance     dd 0

    ThreadID dd 0

    hEventStart  dd 0

    threadControl dd 0

    hBmpNumber0 dd 0
    hBmpNumber1 dd 0
    hBmpNumber2 dd 0
    hBmpNumber3 dd 0
    hBmpNumber4 dd 0
    hBmpNumber5 dd 0
    hBmpNumber6 dd 0
    hBmpNumber7 dd 0
    hBmpNumber8 dd 0
    hBmpNumber9 dd 0

    numbers numberStruct <>
    ship shipStruct <136, INITIAL_Y_SHIP>
    t db 0

.code

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    ; Carregamento dos numeros do placar.

    invoke LoadBitmap, hInstance, imgNumber0
    mov hBmpNumber0, eax

    invoke LoadBitmap, hInstance, imgNumber1
    mov hBmpNumber1, eax

    invoke LoadBitmap, hInstance, imgNumber2
    mov hBmpNumber2, eax

    invoke LoadBitmap, hInstance, imgNumber3
    mov hBmpNumber3, eax

    invoke LoadBitmap, hInstance, imgNumber4
    mov hBmpNumber4, eax

    invoke LoadBitmap, hInstance, imgNumber5
    mov hBmpNumber5, eax

    invoke LoadBitmap, hInstance, imgNumber6
    mov hBmpNumber6, eax

    invoke LoadBitmap, hInstance, imgNumber7
    mov hBmpNumber7, eax

    invoke LoadBitmap, hInstance, imgNumber8
    mov hBmpNumber8, eax

    invoke LoadBitmap, hInstance, imgNumber9
    mov hBmpNumber9, eax

    ; Fim do carregamento dos numeros do placar.

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT

    invoke ExitProcess,eax       ; cleanup & return to operating system

; --------------------- WinMain --------------------------
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

; --------------------- WndProc --------------------------
WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

	LOCAL Ps 	:PAINTSTRUCT
	LOCAL hDC	:DWORD  ; handle do dispositivo (tela)

    LOCAL iLinha :DWORD
    LOCAL iColuna:DWORD

    LOCAL xI:DWORD
    LOCAL yI:DWORD

    LOCAL xMax:DWORD
    LOCAL yMax:DWORD

    LOCAL xbMax:DWORD
    LOCAL ybMax:DWORD

    LOCAL alive:BYTE

    LOCAL countBullet:BYTE

    LOCAL rct:RECT

    .if uMsg == WM_COMMAND

    .elseif uMsg == WM_PAINT

	    invoke BeginPaint, hWin, ADDR Ps
	    mov	hDC, eax

      invoke  Paint_Proc, hWin, hDC

	    invoke EndPaint, hWin, ADDR Ps

    .elseif uMsg == WM_CREATE
        invoke CreateEvent, NULL, FALSE, FALSE, NULL
  	    mov hEventStart, eax
  	    mov eax, OFFSET MainThreadProc
  	    invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID
        mov threadControl, eax

    .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_SPACE
            mov t, 1
        .endif

    .elseif uMsg == WM_BULLET
        .if t == 1
            add ship.points, 5
            mov t, 0
        .endif
        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0
    .endif

    invoke DefWindowProc, hWin, uMsg, wParam, lParam

    ret

WndProc endp

; --------------------- TopXY --------------------------
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

; --------------------- PaintProc --------------------------
Paint_Proc proc hWin:DWORD, hDC:DWORD

	LOCAL hOld:DWORD
	LOCAL memDC:DWORD

    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL sum_Y_Sprite:DWORD

    LOCAL iR:DWORD
    LOCAL iC:DWORD

    LOCAL countN:DWORD
    LOCAL points:DWORD

	invoke  CreateCompatibleDC, hDC
	mov	memDC, eax

  .if ship.points < 10
      add numbers.n1, 5
      mov countN, 1
  .elseif ship.points < 100
      add numbers.n1, 5
      add numbers.n2, 5
      mov countN, 2
  .elseif ship.points < 1000
      add numbers.n1, 5
      add numbers.n2, 5
      add numbers.n3, 5
      mov countN, 3
  .elseif ship.points < 10000
      add numbers.n1, 5
      add numbers.n2, 5
      add numbers.n3, 5
      add numbers.n4, 5
      mov countN, 4
  .elseif ship.points < 100000
      add numbers.n1, 5
      add numbers.n2, 5
      add numbers.n3, 5
      add numbers.n4, 5
      add numbers.n5, 5
      mov countN, 5
  .endif

  mov eax, ship.points
  mov points, eax
  mov ebx, 10
  mov y, 0

  .while TRUE
      div ebx

      inc y

      .if y == 1 && numbers.n1 != 50
          mov x, 580
          mov edx, numbers.n1
      .elseif y == 2 && numbers.n2 != 50
          mov x, 530
          mov edx, numbers.n2
      .elseif y == 3 && numbers.n3 != 50
          mov x, 480
          mov edx, numbers.n3
      .elseif y == 4 && numbers.n4 != 50
          mov x, 430
          mov edx, numbers.n4
      .elseif y == 5 && numbers.n5 != 50
          mov x, 380
          mov edx, numbers.n5
      .endif

      mov iR, edx

      .if eax == 0
          invoke SelectObject, memDC, hBmpNumber0
          invoke BitBlt, hDC, x, 10, 39, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 1
          invoke SelectObject, memDC, hBmpNumber1
          invoke BitBlt, hDC, x, 10, 19, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 2
          invoke SelectObject, memDC, hBmpNumber2
          invoke BitBlt, hDC, x, 10, 39, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 3
          invoke SelectObject, memDC, hBmpNumber3
          invoke BitBlt, hDC, x, 10, 38, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 4
          invoke SelectObject, memDC, hBmpNumber4
          invoke BitBlt, hDC, x, 10, 39, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 5
          invoke SelectObject, memDC, hBmpNumber5
          invoke BitBlt, hDC, x, 10, 39, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 6
          invoke SelectObject, memDC, hBmpNumber6
          invoke BitBlt, hDC, x, 10, 38, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 7
          invoke SelectObject, memDC, hBmpNumber7
          invoke BitBlt, hDC, x, 10, 38, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 8
          invoke SelectObject, memDC, hBmpNumber8
          invoke BitBlt, hDC, x, 10, 38, iR, memDC, 0, 0, SRCCOPY
      .elseif eax == 9
          invoke SelectObject, memDC, hBmpNumber9
          invoke BitBlt, hDC, x, 10, 38, iR, memDC, 0, 0, SRCCOPY
      .endif

      sub points, eax
      mov eax, points

      mov edx, countN
      .if y == edx
          jmp endPrintNumbers
      .endif
  .endw
  endPrintNumbers:

	invoke SelectObject, hDC, hOld
	invoke DeleteDC, memDC

	return 0
Paint_Proc endp

; --------------------- MainThread ------------------------
MainThreadProc PROC USES ecx Param:DWORD

    invoke WaitForSingleObject, hEventStart, 100

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_BULLET, NULL, NULL
        jmp MainThreadProc
    .endif

    ret
MainThreadProc endp

end start
