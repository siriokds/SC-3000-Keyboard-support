
.org 0
COLDBOOT:
	di
	im 1
	ld SP, STACK
	jp START
	
.org $08
.org $10	
.org $18
.org $20	
.org $28
.org $30	

.org $38
	jp Interrupt

.org $66
	retn
	
	
START:
	call 	PSG_Init
	call 	CLEAR_RAM

	call 	WAIT_START_1_sec		; used "WAIT_START_1903_ms" on Sega Mark III
	
	ld 		a, $92					; PPI Init
	out 	(_PORT_DF_), a


	...




CLEAR_RAM:
	ld hl, $C000		; RAM START
	ld de, $C000 + 1	; RAM START + 1
	ld bc, 1024 - 1		; RAM SIZE - 1
	ld (hl), l
	ldir
	ret


WAIT_START_1903_ms:
	ld b, 20
	jr WAIT

WAIT_START_1_sec:
	ld b, 11
WAIT:
	ld de, $FFFF
--:
	ld hl, $39DE
-:
	add hl, de
	jr c, -
	
	djnz --
	ret



PSG_Init:
	exx
	ld hl, PSG_INIT_DATA
	ld c, Port_PSG
	ld b, $04
	otir
	xor a
	exx
	ret
	
PSG_INIT_DATA:
	.db $9F $BF $DF $FF
	


;--------------------------------------------------------------------
; SG-1000 / SC-3000  1-player Joystick/Keyboard routines
;--------------------------------------------------------------------
; SG-1000 with keyboard and SC-3000 returns data from joystick
; merged with data from keyboard.
;
; Bits
; Format: |    5    |     4    |      3       |      2      |      1      |     0     |   
;         | Trig R  |  Trig L  |    Right     |    Left     |    Down     |    Up     |
;         | Ins/Del | Home/Clr | Cursor Right | Cursor Left | Cursor Down | Cursor Up |
;
; INPUT:
;    HL = INPUT DATA ADDRESS
;
; OUTPUT:
;    A = joy/key bits (1 = pressed, 0 = not pressed)
;
;--------------------------------------------------------------------
PPI_PLAYER_1_READ:
	xor a						; write to PPI PortC and readback
	out (_PORT_DE_), a
	in a, (_PORT_DE_)
	or a
	jr +						; Keyboard present


	in a, (PPI_PortA)			; Read Joystick
	cpl							;  A = DATA (in positive format)
	ret

; Keyboard routine
+:
	ld a, $07					; Select Row 7
	out (_PORT_DE_), a
	
	in a, (PPI_PortA)			; Read Joystick
	ld c, a
	

	ld a, $04
	out (_PORT_DE_), a
	in a, (PPI_PortA)
	bit 5, a					; Key Cursor Down 	=> Joy Down
	jp nz, +
	res 1, c
+:

	ld a, $05
	out (_PORT_DE_), a
	in a, (PPI_PortA)
	bit 5, a					; Key Cursor Left	=> Joy Left
	jp nz, +
	res 2, c
+:

	ld a, $06
	out (_PORT_DE_), a
	in a, (PPI_PortA)
	bit 5, a					; Key Cursor Right	=> Joy Right
	jp nz, +
	res 3, c
+:
	bit 6, a					; Key Cursor Up		=> Joy Up
	jp nz, +
	res 0, c
+:

	ld a, $02
	out (_PORT_DE_), a
	in a, (PPI_PortA)
	bit 4, a					; Key Home/Clr		=> Joy Fire 1 (Trig L)
	jp nz, +
	res 4, c
+:

	ld a, $03
	out (_PORT_DE_), a
	in a, (PPI_PortA)
	bit 4, a					; Key Ins/Del		=> Joy Fire 2 (Trig R)
	jp nz, +
	res 5, c
+:
	ld a, c
	cpl							;  A = DATA (in positive format)
	ret	

