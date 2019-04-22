.386                   ; minimum processor needed for 32 bit
.model flat, stdcall   ; FLAT memory model & STDCALL calling
option casemap :none   ; set code to case sensitive

include space-invaders.inc

;
; @authors 17184 --> Iuri Guimarães Slywitch
;          17188 --> Luca Assumpção Dillenburg
;          17162 --> André Amadeu Satorres
;

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

; ###############   definindo as constantes   ################
.Const

.data
; outros
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

; estrutura
    invert    db 0
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

    ship shipStruct <136, INITIAL_Y_SHIP>
    bullet bulletStruct <>
    invadersArray invader 36 dup(<>)

.code
start:
    invoke LoadAssets

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system


; --------------------- LoadAssets --------------------------
LoadAssets proc
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax
    
    invoke LoadBitmap, hInstance, imgInvaders
    mov	hBmpInvaders, eax

    invoke LoadBitmap, hInstance, imgAircraft
    mov hBmpAircraft, eax

    invoke LoadBitmap, hInstance, imgBarrier
    mov hBmpBarrier, eax

    invoke LoadBitmap, hInstance, imgGround
    mov hBmpGround, eax

    invoke LoadBitmap, hInstance, imgTitle_g
    mov hBmpTitle, eax

    invoke LoadBitmap, hInstance, imgBullet
    mov hBmpBullet, eax
LoadAssets endp

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

; Tratar as mensagens mandadas pelo sistema operacional (tais mensagens chegam nesse metodo atraves dos parametros)
; ps: Each message can have additional values associated with it in the two parameters, wParam & lParam

    .if uMsg == WM_COMMAND ;sent by menus, buttons and toolbar buttons.

    .elseif uMsg == WM_PAINT

	    invoke BeginPaint, hWin, ADDR Ps
	    mov	hDC, eax
	
        invoke  Paint_Proc, hWin, hDC
	
	    invoke EndPaint, hWin, ADDR Ps

    .elseif uMsg == WM_CREATE ; This message is sent to WndProc during the CreateWindowEx 
        invoke CreateEvent, NULL, FALSE, FALSE, NULL

	    mov hEventStart, eax
		
	    mov eax, OFFSET ThreadProcInvaders

	    invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID

        inc ThreadID

	    mov hThread, eax

        ; Inicialização do array de invaders.

    .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_LEFT
          .if ship.x >= LEFT_LIMITATOR
            sub ship.x, AMOUNT_SHIP_MOVES
          .endif
        .elseif wParam == VK_RIGHT
          .if ship.x <= RIGHT_LIMITATOR
            add ship.x, AMOUNT_SHIP_MOVES
          .endif

        .elseif wParam == VK_SPACE
          .if bullet.exists == 0 ; verifica se bullet jah existe
            ;Adicionando bala
                ;existencia
            mov bullet.exists, 1
                ;posicao X
            mov eax, ship.x
            add eax, 12
            mov bullet.x, eax
                ;posicao Y
            mov bullet.y, INITIAL_Y_BULLET

            invoke CreateEvent, NULL, FALSE, FALSE, NULL
            mov hEventStart1, eax
            mov  eax, OFFSET ThreadProcBullet
            invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID
            mov threadControl, eax
            invoke CloseHandle, eax
          .endif

        .elseif wParam == VK_RETURN
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
        .if bullet.y <= 0 ; se bala jah saiu da tela
          mov bullet.exists, 0
        .else
          sub bullet.y, 4
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_CLOSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

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

	invoke  CreateCompatibleDC, hDC
	mov	memDC, eax
    
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

    invoke BitBlt, hDC, ship.x, ship.y, ship.w, ship.h, memDC, 0, 0, SRCCOPY

    invoke SelectObject, memDC, hBmpBarrier
    mov hOld, eax

    invoke BitBlt, hDC, 200, 331, 34, 36, memDC, 0, 0, SRCCOPY
    invoke BitBlt, hDC, 294, 331, 34, 36, memDC, 0, 0, SRCCOPY
    invoke BitBlt, hDC, 388, 331, 34, 36, memDC, 0, 0, SRCCOPY

    invoke SelectObject, memDC, hBmpGround
    mov hOld, eax

    invoke BitBlt, hDC, 0, 409, 630, 49, memDC, 0, 0, SRCCOPY

    .if bullet.exists != 0 ; se eh true
        invoke SelectObject, memDC, hBmpBullet
        mov hOld, eax
        invoke BitBlt, hDC, bullet.x, bullet.y, bullet.w, bullet.h, memDC, 0, 0, SRCCOPY
    .endif
	
	invoke SelectObject, hDC, hOld
	invoke DeleteDC, memDC

	return 0
Paint_Proc endp

; --------------------- ThreadProcInvaders --------------------------
ThreadProcInvaders PROC USES ecx Param:DWORD
  invoke WaitForSingleObject, hEventStart, 500

  .if eax == WAIT_TIMEOUT
      invoke PostMessage, hWnd, WM_MOVEMENT, NULL, NULL
      ; Aqui deve-se programar a saida da thread quando acabar o jogo.
      jmp ThreadProcInvaders
  .endif

  ret
ThreadProcInvaders endp

; --------------------- ThreadProcBullet --------------------------
ThreadProcBullet PROC USES ecx Param:DWORD
  invoke WaitForSingleObject, hEventStart1, 30

  .if eax == WAIT_TIMEOUT
      invoke PostMessage, hWnd, WM_BULLET, NULL, NULL
      .if bullet.y != 0
        jmp ThreadProcBullet
      .endif
      invoke ExitThread, threadControl
  .endif

  ret
ThreadProcBullet endp

end start