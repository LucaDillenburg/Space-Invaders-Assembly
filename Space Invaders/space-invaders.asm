.386                   ; minimum processor needed for 32 bit
.model flat, stdcall   ; FLAT memory model & STDCALL calling
option casemap :none   ; set code to case sensitive

include space-invaders.inc

;
; @authors 17184 --> Iuri Guimarães Slywitch
;          17188 --> Luca Assumpção Dillenburg
;          17162 --> André Amadeu Satorres
;

; Deve-se fazer a checagem das teclas enquanto o jogo ainda n comecou, intro == 0
; Fazer os invaders atirarem
; Fazer a pontuacao
; Fazer quantidade de vidas e niveis mais dificeis dos invaders.

; Comando para parar thread da bala.
;invoke ExitThread, threadControl

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
    
    ; Variaveis para controlar as threads
    threadControlMovement dd 0
    threadControlBullet   dd 0
    threadControlBalloon  dd 0

    hEventStart  dd 0
    hEventStart1 dd 0
    hEventStart2 dd 0

    hBmpInvaders dd 0
    hBmpAircraft dd 0
    hBmpBarrier  dd 0
    hBmpGround   dd 0
    hBmpTitle    dd 0
    hBmpBullet   dd 0
    hBmpIntro1   dd 0
    hBmpIntro2   dd 0
    hBmpBalloon  dd 0

    rNumber dd 0

; auxiliares (apagar)
    header_format db "A: %d",0
    buffer    db 256 dup(?)
    msg1 db "a",0

; estrutura
    isInvert       db 0
    directionRight db 1

    ship shipStruct <136, INITIAL_Y_SHIP>
    bullet bulletStruct <>
    bulletInvaders bulletStInv 6 dup(<1,1>)
    invaders invader AMOUNT_INVADERS dup(<1,1>)
    balloon balloonStruct <>

    score dd 0

    qttX dd 0
    qttY dd 0

    ; Controlar comeco do jogo
    intro dd 1

.code

getRandomNumber proc uses eax
        invoke GetTickCount
        invoke nseed, eax
        ; Random number de 0 a 11
        invoke nrandom, 12
        mov rNumber, eax
        ret
getRandomNumber endp

getRandomSide proc uses eax
        invoke GetTickCount
        invoke nseed, eax
        ; Random number de 0 a 1
        invoke nrandom, 2
        mov balloon.side, eax
        ret
getRandomSide endp

start:
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

    invoke LoadBitmap, hInstance, imgIntro1
    mov hBmpIntro1, eax

    invoke LoadBitmap, hInstance, imgIntro2
    mov hBmpIntro2, eax

    invoke LoadBitmap, hInstance, imgBalloon
    mov hBmpBalloon, eax

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

; Tratar as mensagens mandadas pelo sistema operacional (tais mensagens chegam nesse metodo atraves dos parametros)
; ps: Each message can have additional values associated with it in the two parameters, wParam & lParam

    .if uMsg == WM_COMMAND ;sent by menus, buttons and toolbar buttons.

    .elseif uMsg == WM_PAINT

	    invoke BeginPaint, hWin, ADDR Ps
	    mov	hDC, eax
	
        invoke  Paint_Proc, hWin, hDC
	
	    invoke EndPaint, hWin, ADDR Ps

    .elseif uMsg == WM_CREATE ; This message is sent to WndProc during the CreateWindowEx 
        ; Thread dos invaders.

        invoke CreateEvent, NULL, FALSE, FALSE, NULL

	    mov hEventStart, eax
		
	    mov eax, OFFSET ThreadProcInvaders

	    invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID

        inc ThreadID

	    mov threadControlMovement, eax

        ; Thread da bala.

        invoke CreateEvent, NULL, FALSE, FALSE, NULL

        mov hEventStart1, eax

        mov  eax, OFFSET ThreadProcBullet

        invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID

        inc ThreadID

        mov threadControlBullet, eax

        ; Inicialização do array de invaders.
        mov esi, offset invaders
        mov iLinha, 0
        mov iColuna, 0
        loopInitializeInvaders:
            ; x = spaceBetweenInvaders * iColuna + posXFirst
            mov eax, spaceBetweenInvaders
            add eax, 34
            mul iColuna
            add eax, posXFirst
            mov dword ptr [esi], eax ;.x

            ; y = spaceBetweenLines * iLinha + posYFirst
            mov eax, spaceBetweenLines
            add eax, 20
            mul iLinha
            add eax, posYFirst
            mov dword ptr [esi+4], eax ;.y

            mov byte ptr[esi+8], 1

            .if iColuna == INVADERS_PER_LINE - 1
                inc iLinha
                mov iColuna, 0
            .else
                inc iColuna
            .endif

            add esi, INVADER_SIZE

            cmp iLinha, 6
            jne loopInitializeInvaders

    .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_LEFT
            .if intro == 0
                .if ship.x >= LEFT_LIMITATOR
                    sub ship.x, AMOUNT_SHIP_MOVES
                .endif
            .endif

        .elseif wParam == VK_RIGHT
            .if intro == 0
                .if ship.x <= RIGHT_LIMITATOR
                    add ship.x, AMOUNT_SHIP_MOVES
                .endif
            .endif

        .elseif wParam == VK_SPACE
            .if intro == 0
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
                .endif
            .endif

        .elseif wParam == VK_RETURN
            .if intro == 1
                ; Uso estas variaveis para controlar o controle da tela antes do jogo comecar.
                mov directionRight, 0
                mov isInvert, 0
            .endif
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE

    .elseif uMsg == WM_MOVEMENT
        .if intro == 0
            ; al: quanto vai somar em X
            ; ah: quanto vai somar em Y

            ; verifica se vai mudar direcao e se precisar mudar direcao, a muda
            ; get numero de bytes ateh ultimo invader da primeira linha
            mov eax, INVADERS_PER_LINE
            sub eax, 2
            mov ebx, INVADER_SIZE
            mul ebx
            ; vai com esi para a posicao do ultimo invader da primeira linha
            mov esi, offset invaders
            mov ecx, dword ptr [esi] ;.x primeiro da linha
            add esi, eax
            mov ebx, dword ptr [esi] ;.x ultimo da linha
            ; verifica se vai mudar de direcao e pular linha
            ; Checa se o ultimo invader da primeira linha atingiu o fim do tamanho qualificado

            mov qttY, 0
            mov qttX, 0

            .if directionRight == 1
                .if ebx == RIGHT_LIMITATOR_INVADERS
                    mov directionRight, 0
                    mov qttY, AMOUNT_INVADERS_MOVE_Y
                .else
                    mov qttX, AMOUNT_INVADERS_MOVE_X
                .endif
            .elseif directionRight == 0
                .if ecx == LEFT_LIMITATOR_INVADERS
                    mov directionRight, 1
                    mov qttY, AMOUNT_INVADERS_MOVE_Y
                .else
                    mov qttX, -AMOUNT_INVADERS_MOVE_X
                .endif
            .endif

            ; mover cada invader
            mov esi, offset invaders
            mov ecx, 0
            mov cl, 0
            
            loopMoveInvaders:
                ; x
                mov eax, qttX
                add dword ptr [esi], eax ; .x

                ; y
                mov eax, qttY
                add dword ptr [esi+4], eax ; .y

                add esi, INVADER_SIZE
                inc cl

                cmp cl, AMOUNT_INVADERS
                jne loopMoveInvaders

            .if isInvert == 0
                mov isInvert, 1
            .else
                mov isInvert, 0
            .endif

            call getRandomNumber

            ;invoke wsprintf, ADDR buffer1, ADDR header_format1, rNumber
            ;invoke MessageBox, NULL, ADDR buffer1, NULL, MB_OK

            .if rNumber < 6
                ; esi armazena o vetor invaders enquanto edi esta com o vetor bulletInvaders, o qual contem as balas dos invaders.
                mov esi, offset invaders
                mov edi, offset bulletInvaders

                ; Setando a posicao para o invader da coluna sorteada.
                mov eax, rNumber
                mov ebx, INVADER_SIZE
                mul ebx

                ; Colocando o vetor na ultima posicao da coluna sorteada conforme random.
                add esi, eax
                add esi, 270

                ; Movendo o vetor de bala para a bala do invader daquela coluna.
                add edi, eax

                ; Verificar se tiro ja existe na coluna.
                .if byte ptr [edi+8] == 0
                    mov cl, 0

                    loopCheckCollumn:
                        .if byte ptr [esi+8] == 1
                            mov cl, 6
                            
                            ; x do invader
                            mov eax, dword ptr [esi]
                            ; Alinhamento da bala
                            add eax, 14
                            ; Adicionando ao vetor da bala a posicao x inicial da bala.
                            mov dword ptr [edi], eax

                            ; y do invader
                            mov eax, dword ptr [esi+4]

                            ; Alinhamento da bala
                            add eax, 22
                            ; Adicionando ao vetor da bala a posicao y inicial da bala.
                            mov dword ptr [edi+4], eax

                            mov byte ptr [edi+8], 1                                                                                    
                        .else
                            ; Indo checar a posicao superior
                            sub esi, 54
                        .endif

                        .if cl != 6
                            inc cl
                            jmp loopCheckCollumn
                        .endif
                .endif
            .endif
        .endif

        invoke InvalidateRect, hWnd, NULL, TRUE
    .elseif uMsg == WM_BULLET
        .if intro == 0
            .if bullet.exists != 0
                mov esi, offset invaders
                mov cl, 0

                loopInvaders:
                    mov eax, dword ptr [esi]      ; xI
                    mov xI, eax
                    mov eax, dword ptr [esi+4]    ; yI
                    mov yI, eax

                    ; Colocando na variavel xMax o valor maximo do invader na localizacao x.
                    mov eax, xI
                    mov xMax, eax
                    add xMax, WIDTH_INVADER

                    ; Colocando na variavel yMax o valor maximo do invader na localizacao y.
                    mov eax, yI
                    mov yMax, eax
                    add yMax, HEIGHT_INVADER

                    ; Aqui temos um retangulo o qual determina toda a area ocupada por aquele invader.
                    ; O esquema abaixo representa melhor.
                    ;
                    ; x y          xMax
                    ;
                    ;
                    ; yMax         xMax+yMax
                    ;
                    ; Quando comparamos areas no if, checaremos qualquer evento de colisao.

                    mov eax, 0
                    mov al, byte ptr [esi+8] ; isAlive
                    mov alive, al

                    ; Estas proximas variaveis representam os xI e yI da bala.

                    mov eax, bullet.x
                    mov xbMax, eax
                    add xbMax, 6

                    mov eax, bullet.y
                    mov ybMax, eax
                    add ybMax, 16

                    ; A partir deste momento, devo checar a colisao somente se o invader esta vivo.
                    ; Checagem para ver se o invader esta vivo...
                    .if alive != 0
                        mov eax, bullet.x
                        mov ebx, xbMax
                        .if eax >= xI && eax <= xMax
                            mov eax, bullet.y
                            mov ebx, ybMax
                            .if eax >= yI && eax <= yMax
                                mov byte ptr [esi+8], 0
                                mov bullet.exists, 0
                            .elseif ebx >= yI && ebx < yMax
                                mov byte ptr [esi+8], 0
                                mov bullet.exists, 0
                            .endif
                        .elseif ebx >= xI && ebx < xMax
                            mov eax, bullet.y
                            mov ebx, ybMax
                            .if eax >= yI && eax <= yMax
                                mov byte ptr [esi+8], 0
                                mov bullet.exists, 0
                            .elseif ebx >= yI && ebx < yMax
                                mov byte ptr [esi+8], 0
                                mov bullet.exists, 0
                            .endif
                        .endif
                    .endif

                    ; Incremento para checagem da saida.
                    inc cl

                    add esi, INVADER_SIZE

                    ; Condicao de saida.
                    cmp cl, AMOUNT_INVADERS
                    jne loopInvaders

                mov cl, 0
                mov ch, 0
                mov esi, offset invaders

                checkWin:
                    add ch, byte ptr [esi+8]
                    
                    inc cl

                    add esi, INVADER_SIZE

                    cmp cl, AMOUNT_INVADERS
                    jne checkWin

                .if ch == 0
                    mov intro, 1
                    mov directionRight, 1
                    mov isInvert, 0
                .elseif ch == 12 || ch == 24
                    invoke CreateEvent, NULL, FALSE, FALSE, NULL

                    mov hEventStart2, eax

                    mov  eax, OFFSET ThreadProcBalloon

                    invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR ThreadID

                    mov threadControlBalloon, eax
                .endif

                sub bullet.y, 4
            .endif

            .if bullet.y <= 0 ; se bala jah saiu da tela
                mov bullet.exists, 0
            .endif

            mov esi, offset bulletInvaders

            mov countBullet, 0

            loopBulletMovement:
                .if byte ptr [esi+8] == 1
                    add dword ptr [esi+4], 4

                    mov eax, dword ptr[esi]
                    mov xbMax, eax
                    add xbMax, 6

                    mov eax, dword ptr[esi+4]
                    mov ybMax, eax
                    add ybMax, 16

                    mov eax, ship.x
                    mov xMax, eax
                    add xMax, 34

                    mov eax, ship.y
                    mov yMax, eax
                    add yMax, 20

                    ; bullet.x - dword ptr [esi]
                    ; bullet.y - dword ptr [esi+4]
                    ; xI - ship.x
                    ; yI - ship.y

                    mov eax, dword ptr [esi]
                    mov ebx, xbMax
                    .if eax >= ship.x && eax <= xMax
                        mov eax, dword ptr [esi+4]
                        mov ebx, ybMax
                        .if eax >= ship.y && eax <= yMax
                            mov byte ptr [esi+8], 0
                            dec ship.lives
                        .elseif ebx >= ship.y && ebx < yMax
                            mov byte ptr [esi+8], 0
                            dec ship.lives
                        .endif
                    .elseif ebx >= ship.x && ebx < xMax
                        mov eax, dword ptr [esi+4]
                        mov ebx, ybMax
                        .if eax >= ship.y && eax <= yMax
                            mov byte ptr [esi+8], 0
                            dec ship.lives
                        .elseif ebx >= ship.y && ebx < yMax
                            mov byte ptr [esi+8], 0
                            dec ship.lives
                        .endif
                    .endif

                    ; Ando com a bala se esta ainda existe...
                    .if byte ptr [esi+8] == 1
                        mov eax, dword ptr [esi+4]
                        add eax, 16
                        .if eax == 409
                            mov byte ptr[esi+8], 0
                        .endif
                    .endif

                    .if ship.lives == -1
                        mov intro, 1
                        jmp updateScrn
                        ;invoke ExitThread, threadControl
                    .endif
                .endif

                inc countBullet

                .if countBullet != 6
                    add esi, 9
                    jmp loopBulletMovement
                .endif
            updateScrn:
            invoke InvalidateRect, hWnd, NULL, TRUE
        .endif

    .elseif uMsg == WM_BALLOON
        .if intro == 0
            .if balloon.alive == 0
                ; Programacao da movimentacao do balao...
                ; Deve-se sortear a posicao do balao
                call getRandomSide

                ; Configuracoes para o balao, em relacao a sua quantidade de movimento e posicao maxima ate a borda.
                .if balloon.side == 0
                    mov balloon.x, -20
                    mov balloon.y, 10
                    mov balloon.speed, 5
                    mov balloon.max, 630
                .elseif balloon.side == 1
                    mov balloon.x, 640
                    mov balloon.y, 10
                    mov balloon.speed, -5
                    mov balloon.max, -30
                .endif

                mov balloon.alive, 1
            .endif

            ; Checando se o balao atingiu ao fim do percurso.
            mov eax, balloon.x
            .if eax != balloon.max
                mov eax, balloon.speed
                add balloon.x, eax
            .endif

            invoke InvalidateRect, hWnd, NULL, TRUE
        .endif

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

    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL sum_Y_Sprite:DWORD

    LOCAL iR:DWORD
    LOCAL iC:DWORD

    LOCAL count:BYTE

	invoke  CreateCompatibleDC, hDC
	mov	memDC, eax
    
    .if intro == 1
        .if isInvert == 0
            .if directionRight == 0
                mov intro, 0
                mov directionRight, 1
            .endif

            mov isInvert, 1

            invoke SelectObject, memDC, hBmpIntro2
            mov	hOld, eax

            invoke BitBlt, hDC, 0, 0, 650, 500, memDC, 0, 0, SRCCOPY
        .else
            mov isInvert, 0

            invoke SelectObject, memDC, hBmpIntro1
            mov	hOld, eax

            invoke BitBlt, hDC, 0, 0, 650, 500, memDC, 0, 0, SRCCOPY
        .endif
    .else
        invoke SelectObject, memDC, hBmpInvaders
        mov	hOld, eax

        .if isInvert == 0
            mov sum_Y_Sprite, 0
        .else
            mov sum_Y_Sprite, HEIGHT_INVADER
        .endif

        mov esi, offset invaders
        mov iC, 0 ;iColuna
        mov iR, 0 ;iLinha
        .WHILE TRUE
            .if byte ptr [esi+8] != 0 ;verifica se estah vivo
                mov eax, dword ptr [esi]    ;.x
                mov x, eax

                mov eax, dword ptr [esi+4]  ;.y
                mov y, eax

                ; eax = eax * HEIGHT_INVADER + sum_Y_Sprite
                mov eax, 40
                mul iR
                add eax, sum_Y_Sprite

                invoke BitBlt, hDC, x, y, WIDTH_INVADER, HEIGHT_INVADER, memDC, 0, eax, SRCCOPY
            .endif

            ; Checar condicao de parada / continuar colocando na tela os invaders.
            .if iC == 5
                mov iC, 0
                
                .if iR == 5
                    jmp endPrintInvaders
                .else
                    inc iR
                .endif
            .else
                inc iC
            .endif

            ; Proximo invader
            add esi, INVADER_SIZE
        .ENDW
        endPrintInvaders:

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

        mov esi, offset bulletInvaders

        mov count, 0

        loopBullet:
            .if byte ptr [esi+8] == 1
                invoke SelectObject, memDC, hBmpBullet
                mov hOld, eax

                invoke BitBlt, hDC, dword ptr[esi], dword ptr[esi+4], 6, 16, memDC, 0, 0, SRCCOPY
            .else
                add esi, 9
            .endif

            .if count != 6
                inc count
                jmp loopBullet
            .endif

        .if balloon.alive == 1
            invoke SelectObject, memDC, hBmpBalloon
            mov hOld, eax

            invoke BitBlt, hDC, balloon.x, balloon.y, 30, 16, memDC, 0, 0, SRCCOPY
        .endif
    .endif
	
	invoke SelectObject, hDC, hOld
	invoke DeleteDC, memDC

	return 0
Paint_Proc endp

; --------------------- ThreadProcInvaders ------------------------
ThreadProcInvaders PROC USES ecx Param:DWORD
    invoke WaitForSingleObject, hEventStart, 500

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_MOVEMENT, NULL, NULL
        ; Saida do jogo, game over.
        jmp ThreadProcInvaders
    .endif

    ret
ThreadProcInvaders endp

; --------------------- ThreadProcBullet --------------------------
ThreadProcBullet PROC USES ecx Param:DWORD
    invoke WaitForSingleObject, hEventStart1, 25

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_BULLET, NULL, NULL
        jmp ThreadProcBullet
    .endif

    ret
ThreadProcBullet endp

; --------------------- ThreadProcBalloon -------------------------
ThreadProcBalloon PROC USES ecx Param:DWORD
    invoke WaitForSingleObject, hEventStart2, 600

    .if eax == WAIT_TIMEOUT
        invoke PostMessage, hWnd, WM_BALLOON, NULL, NULL
        .if balloon.alive == 1
            jmp ThreadProcBalloon
        .endif
    .endif

    ; Saio da thread se o balao nao existe mais
    invoke ExitThread, threadControlBalloon

    ret
ThreadProcBalloon endp

end start