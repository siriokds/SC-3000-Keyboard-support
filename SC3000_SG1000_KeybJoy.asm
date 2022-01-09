PPI_Setting         = 0x92
PPI_PortC           = 0xDE
PPI_Control         = 0xDF
JOY_PortA           = 0xDC
JOY_PortB           = 0xDD

KEYB_Detected       = 0x00
KEYB_NotDetected    = 0xFF

PPI_Keyboard		DS 1		; this byte must be defined in RAM area (>= $C000 for internal RAM)





; 1) Call this at start of the game
;----------------------------------------------------------------
;================================================================
SC3K_InputInit:
;================================================================
;----------------------------------------------------------------
	ld		a,PPI_Setting
	out		(PPI_Control),a

	ld		a, KEYB_NotDetected
	ld		(PPI_Keyboard),a	; save it, 0 = keyboard present

	ld		a,0x55
	call	.ppi_test
	ld		c, a
	ld		a,0xaa
	call	.ppi_test
	
	or		c					; merge the two attempts
	ld		(PPI_Keyboard),a	; save it, 0 = keyboard present

	ld		a,0x07				; default row 7 (joystick)
	out		(PPI_PortC),a
	ret
; b = test value
.ppi_test	
	ld		b, a
	out		(PPI_PortC),a
	in		a,(PPI_PortC)
	cp		b
	ld		a, KEYB_Detected	; "xor a" cannot be used. Zero Flag must be intact.
	jr		z, .ppi_test_noerr
	dec		a					; c = 0xFF if not detected
.ppi_test_noerr
	ret


; 2) Call this to obtain joystick + keyboard keys
;
; OUTPUT:
;    A = joy/key bits (1 = pressed, 0 = not pressed)
;
;    format bits:   5   |   4   |   3   |   2   |   1   |   0   
;                 TrigR | TrigL | Right | Left  | Down  |  Up  |
;----------------------------------------------------------------
;================================================================
SC3K_InputRead:
;================================================================
;----------------------------------------------------------------
	call	KeybJoyRead
	cpl
	and		3Fh
	ret






;---------------------------------------------------------------
PpiRowRead:
;---------------------------------------------------------------
	ld		a, b
	out		(PPI_PortC), a	; no effect on SG-1000
;===============================================================
JoyRead:
;===============================================================
	in		a, (JOY_PortA)
	dec		b
	ret


; Destroy registers: BC
; OUTPUT: A
;===============================================================
KeybJoyRead:
;===============================================================
	ld		a, (PPI_Keyboard)
	or		a
	jr		nz, JoyRead


; --- ROW 7 --------------------------------------------
	ld		b, 7			; READ JOYSTICK ROW
	call	PpiRowRead
	ld		c, a

; --- ROW 6 --------------------------------------------
	call	PpiRowRead
    bit		5,a
	jr		nz, .noKeyRIGHT:
	res		3, c			; CURSOR RIGHT => Joy Right
.noKeyRIGHT:
    bit		6,a
	jr		nz, .noKeyUP:
	res		0, c			; CURSOR UP => Joy Up
.noKeyUP:
	in		a, (JOY_PortB)
	bit		1,a				; Graph
	jr		nz,.noKeyGraph:
	res		4, c			; Left Trigger
.noKeyGraph:

; --- ROW 5 --------------------------------------------
	call	PpiRowRead
    bit		5,a
	jr		nz, .noKeyLEFT:
	res		2, c			; CURSOR LEFT => Joy Left
.noKeyLEFT:

; --- ROW 4 --------------------------------------------
	call	PpiRowRead
    bit		5,a
	jr		nz, .noKeyDOWN:
	res		1, c			; CURSOR DOWN => Joy Down
.noKeyDOWN:

; --- ROW 3 --------------------------------------------
	call	PpiRowRead
	bit		4,a				; InsDel
	jr		nz,.noKeyInsDel:
	res		5, c			; Right Trigger
.noKeyInsDel:
	
; --- ROW 2 --------------------------------------------
	call	PpiRowRead
	bit		4,a				; Home
	jr		nz,.noKeyHome:
	res		4, c			; Left Trigger
.noKeyHome:

; --- ROW 1 --------------------------------------------
	dec		b

; --- ROW 0 --------------------------------------------
	call	PpiRowRead
	bit		4,a				; Eng Dier's
	jr		nz,.noKeyEngDiers:
	res		5, c			; Right Trigger
.noKeyEngDiers:
	ld 		a, c
	
.keybExit:
	cpl
	ret
