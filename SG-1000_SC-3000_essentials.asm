.define PPI_PortA			$DC
.define PPI_PortB			$DD
.define PPI_PortC			$DE
.define PPI_PortCtrl		$DF

.define PSG_Port			$7F
	
.define VDP_PortData		$BE
.define VDP_PortCommand		$BF
.define VDP_PortStatus		$BF
	
.define JoystickData		$C002
	
.define RAMSTART			$C000
.define RAMSIZE				$1024
.define STACK				(RAMSTART + RAMSIZE)

.org 0
COLDBOOT:
	di
	im 1
	ld SP, STACK
	jp START
	
.org $0008
.org $0010	
.org $0018
.org $0020	
.org $0028
.org $0030	

.org $0038
	jp Interrupt

.org $0066
	jp NMI_Handler
	
	
START:
	; 1) Silence PSG
	call 	PSG_Init

	; 2) Wait for VDP ready
	call 	VDP_INIT_DELAY

	; 3) Screen off
	ld		bc, $8001
	call	WRTVDP
	
	; 4) CLEAR_RAM
	ld 	hl, RAMSTART
	ld 	de, RAMSTART + 1
	ld 	bc, RAMSIZE - 1
	ld 	(hl), l
	ldir

	; PPI Init
	ld 		a, $92
	out 	(PPI_PortCtrl), a


	... continue with code ...






VDP_INIT_DELAY:			; close to 1000 ms
	ld b, 11			; Loretta waits for 1903 ms, Gulkave waits for 536 ms

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
	ld c, PSG_Port
	ld b, $04
	otir
	xor a
	exx
	ret
	
PSG_INIT_DATA:
	.db $9F $BF $DF $FF
	



WRTVDP:
	ld a,b
	out (VDP_PortCommand),a
	ld a,c
	or $80
	out (VDP_PortCommand),a
	ret



NMI_Handler:
	retn			




Interrupt:
	push af
	push bc
	push de
	push hl
	exx
	ex af, af'
	push af
	push bc
	push de
	push hl
	push ix
	push iy

	in a, (VDP_PortStatus)
	
	call PPI_PLAYER_1_READ
	ld	 (JoystickData), a
	
	... interrupt code here ...
	
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af, af'
	pop hl
	pop de
	pop bc
	pop af

	ei
	ret		; IM 1 doesn't need RETI









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
	ld a, 7						; Select Row 7
	out (PPI_PortC), a
	
	in a, (PPI_PortC)			; Readback to detect keyboard
	cp 7
	jr z, +						; Keyboard present


	in a, (PPI_PortA)			; Read Joystick
	cpl							;  A = DATA (in positive format)
	ret

; Keyboard routine
+:
	in a, (PPI_PortA)			; Read Joystick
	ld c, a
	

	ld a, $04
	out (PPI_PortC), a
	in a, (PPI_PortA)
	bit 5, a					; Key Cursor Down 	=> Joy Down
	jp nz, +
	res 1, c
+:

	ld a, $05
	out (PPI_PortC), a
	in a, (PPI_PortA)
	bit 5, a					; Key Cursor Left	=> Joy Left
	jp nz, +
	res 2, c
+:

	ld a, $06
	out (PPI_PortC), a
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
	out (PPI_PortC), a
	in a, (PPI_PortA)
	bit 4, a					; Key Home/Clr		=> Joy Fire 1 (Trig L)
	jp nz, +
	res 4, c
+:

	ld a, $03
	out (PPI_PortC), a
	in a, (PPI_PortA)
	bit 4, a					; Key Ins/Del		=> Joy Fire 2 (Trig R)
	jp nz, +
	res 5, c
+:
	ld a, c
	cpl							;  A = DATA (in positive format)
	ret	

