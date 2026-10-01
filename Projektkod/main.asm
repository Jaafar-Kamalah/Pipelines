	rjmp START
////////////////////INTERRUPTS/////////////////
	.org OC1Aaddr
	rjmp SEND_BOARD                 
	.org INT_VECTORS_SIZE
	.equ COUNTER = 70				
////////////////////FILES//////////////////////
	.include "TWI-Drivers.asm"
	.include "SPI-Drivers.asm"
	.include "delays.asm"
	.include "DAMatrix.asm"
	.include "joystick.asm"
	.include "key_read.asm"
	.include "key_send.asm"
	.include "audio.asm"
////////////////////DATA///////////////////////
	.dseg
BOARD:
	.byte 64
DAMATRIX:
	.byte 24
COLUMN:
	.byte 1
LEVEL:
	.byte 2
LEVEL_DONE:
	.byte 2
CURSOR_POSITION:
	.byte 1
CURSOR_COLOR:
	.byte 1
CURSOR_COUNTER:
	.byte 1
SELECT_FLAG:
	.byte 1
PREV_CURSOR_POSITION:
	.byte 1
SELECTED_POSITION:
	.byte 1
FAILURE_COUNTER:
	.byte	1
///////////////////LISTS//////////////////////
.cseg
LVL1:	
	.db 0, red, 6, yellow, 6, green, 4, pink,2, blue, 8, green, 2, yellow, 2, blue, 7, cyan, 0, red, 2, cyan, 9, pink, $FF, $FF
LVL1_DONE:
	.db re,ye,ye,ye,ye,ye,ye,ye, re,ye,bl,bl,bl,bl,gr,gr, re,ye,bl,pu,pu,bl,bl,gr, re,ye,bl,bl,pu,pu,pu,gr, re,ye,ye,bl,bl,bl,pu,pu, re,cy,cy,cy,cy,cy,re,pu, re,cy,re,re,re,re,re,pu, re,re,re,pu,pu,pu,pu,pu

LVL2:
	.db 3, red, 3, blue, 2, cyan, 2, green, 1, green, 7, pink, 3, yellow, 0, pink, 9, blue, 5, yellow, 0, cyan, 11, red, $FF, $FF
LVL2_DONE:
	.db re,re,re,re,bl,bl,bl,bl, re,cy,cy,bl,bl,gr,gr,gr, re,cy,bl,bl,pu,pu,pu,pu, re,cy,bl,ye,pu,cy,cy,cy, re,cy,bl,ye,ye,cy,bl,cy, re,cy,bl,bl,ye,cy,bl,cy, re,cy,cy,bl,bl,bl,bl,cy, re,re,cy,cy,cy,cy,cy,cy
ADJACENT:
	.db 8, -8, -1, 1, 0, 0
/////////////////DEFINITIONS///////////////////
	.equ black = 0
	.equ blue = 8 | 1
	.equ green = 8 | 2
	.equ cyan = 8 | 3
	.equ red = 8 | 4
	.equ pink = 8 | 5
	.equ yellow = 8 | 6
	.equ white = 8 | 7

	.equ bl = 1
	.equ gr = 2
	.equ cy = 3
	.equ re = 4
	.equ pu = 5
	.equ ye = 6
///////////////INITIALIZATION//////////////////
START:
	rcall SPI_INIT
	rcall TWI_SPEED_INIT
	rcall TIMER_INIT
	rcall JOY_RIGHT_INIT          ; Initializes AD conversion for right joystick
	rcall SRAM_INIT               ; Initializes data, clears board
	rcall SEND_BOARD_INIT         ; Initializes X pointer for interuptions

	rcall LOAD_LVL1               ; Lvl 1 -> LEVEL
	rcall LOAD_BOARD              ; LEVEL -> BOARD
	rcall CURSOR_SEND             ; CURSOR -> BOARD
	rcall AUDIO_INIT
	sei					          ;Allow interrupts globally
//////////////////PROGRAM//////////////////////
MAIN:
	rcall LOAD_DAMATRIX           ; BOARD - > DAMATRIX
	rcall KEY_READ		
	rcall KEY_SEND
	rjmp MAIN
////////////////INTERUPT TIMER/////////////////
TIMER_INIT:
	ldi r16, (1<<WGM12) | (1<<CS12)
	sts TCCR1B, r16
	ldi r16, HIGH(COUNTER)
	sts OCR1AH, r16
	ldi r16, LOW(COUNTER)
	sts OCR1AL, r16
	ldi r16, (1<<OCIE1A)
	sts TIMSK1, r16
	ret
////////////////CLEAR BOARD///////////////////
SRAM_INIT:
	push r16
	push r17
	push ZL
	push ZH

	rcall DATA_INIT                ; Initializes SRAM data
	rcall BOARD_INIT               ; Clears board

	pop ZH
	pop ZL
	pop r17
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_INIT:
	ldi r16, 1
	sts COLUMN, r16
	clr r16
	sts SELECT_FLAG, r16
	sts CURSOR_POSITION, r16
	sts CURSOR_COUNTER, r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BOARD_INIT:
	ldi ZH, HIGH(BOARD)
	ldi ZL, LOW(BOARD)
	clr r16
	ldi r17, 64
CLR_NEXT_SEG:
	st Z+,r16
	dec r17
	brne CLR_NEXT_SEG
	ret	
///////////////LEVEL SELECTION/////////////////
LOAD_LVL1:
	push r16
	push r17

	ldi r16, HIGH(LVL1*2)
	ldi r17, LOW(LVL1*2)
	ldi r18, HIGH(LVL1_DONE*2)
	ldi r19, LOW(LVL1_DONE*2)
	rcall LOAD_LEVEL              ; Saves level in SRAM

	pop r17
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_LVL2:
	push r16
	push r17

	ldi r16, HIGH(LVL2*2)
	ldi r17, LOW(LVL2*2)
	ldi r18, HIGH(LVL2_DONE*2)
	ldi r19, LOW(LVL2_DONE*2)
	rcall LOAD_LEVEL              ; Saves level in SRAM

	pop r17
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_LEVEL:
	sts LEVEL, r16
	sts LEVEL+1, r17
	sts LEVEL_DONE, r18
	sts LEVEL_DONE+1, r19
	ret
///////////////LEVEL -> BOARD//////////////////
LOAD_BOARD:
	push r16
	push YL
	push YH
	push ZL
	push ZH

	rcall LOAD_BOARD_INIT
	rcall LOAD_BOARD_LEVEL

	pop ZH
	pop ZL
	pop YH
	pop YL
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_BOARD_INIT:
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)
	lds ZH, LEVEL
	lds ZL, LEVEL+1
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_BOARD_LEVEL:
	lpm r16, Z+                       ; Spaces
	cpi r16, $FF
	breq BOARD_LOADED
	add YL, r16
	lpm r16, Z+                       ; Color
	st Y+, r16
	rjmp LOAD_BOARD_LEVEL
BOARD_LOADED:
	ret	
///////////////BOARD -> DAMATRIX//////////////////
LOAD_DAMATRIX:
	push r16
	push r17
	push r18
	push r19
	push r20
	push YL
	push YH
	push ZL
	push ZH

	rcall LOAD_DAMATRIX_INIT
	rcall LOAD_DAMATRIX_BOARD

	pop ZH
	pop ZL
	pop YH
	pop YL
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16

	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_DAMATRIX_INIT:
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)
	ldi ZH, HIGH(DAMATRIX)
	ldi ZL, LOW(DAMATRIX)
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_DAMATRIX_BOARD:
	ldi r16, 8
NEXT_DAMATRIX_ROW:
	rcall LOAD_DAMATRIX_ROW    
	st Z+, r17
	st Z+, r18
	st Z+, r19 
	dec r16
	brne NEXT_DAMATRIX_ROW
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_DAMATRIX_ROW:
	push r16

	ldi r20, 8
NEXT_DAMATRIX_BYTE:
	ld r16, Y+
	ror r16
	ror r17                   ; Blue
	ror r16
	ror r18                   ; Green
	ror r16
	ror r19                   ; Red
	dec r20
	brne NEXT_DAMATRIX_BYTE

	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
POINT_AT_CURSOR:
	push r17
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)
	lds r17, CURSOR_POSITION
	add YL, r17
	pop r17
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_LEVEL_DONE:
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)
	lds ZH, LEVEL_DONE
	lds ZL, LEVEL_DONE+1
	clr r18
CLD_LOOP:
	inc r18                   ; Loop counter
	lpm r16, Z+	
	ld r17, Y+
	andi r17, 7
	cp r16, r17
	breq CLD_LOOP

	lds r17, CURSOR_POSITION  
	inc r17                  
	cp r17, YL                ; If (Z = Cursor position + 1) == (We are comparing cursor)
	brne CLD_DONE
	
	lds r17, CURSOR_COLOR
	andi r17, 7
	cp r17,r16               ; Check again with cursor color instead of blinking cursor
	breq CLD_LOOP

CLD_DONE:
	cpi r18, 64
	brlo LEVEL_NOT_DONE

	rcall SEND_WIN           ; Level done
	rcall SRAM_INIT
	rcall SWITCH_LEVEL
	rcall LOAD_BOARD
	rcall CURSOR_SEND
LEVEL_NOT_DONE:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SWITCH_LEVEL:
	lds r16, LEVEL+1
	cpi r16, LOW(LVL1*2)
	breq LOAD_LEVEL_2
	rcall LOAD_LVL1
	rjmp SL_EXIT
LOAD_LEVEL_2:
	rcall LOAD_LVL2
SL_EXIT:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
