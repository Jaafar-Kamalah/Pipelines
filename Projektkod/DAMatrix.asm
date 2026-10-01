/////////////////DEFINITIONS///////////////////
	.equ SS = PB2
///////////////Print DAMATRIX//////////////////
SEND_BOARD:
	push r16
	in r16, SREG
	push r16
	push r17
	push ZH
	push ZL

	rcall SEND_CURSOR
	rcall SEND_COLUMN
	rcall COLUMN_COUNTER

	pop ZL
	pop ZH
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SEND_CURSOR:
	lds r16, CURSOR_COUNTER
	inc r16
	sts CURSOR_COUNTER, r16
	brne SKIP_SEND_CURSOR
	rcall CURSOR_BLINK
SKIP_SEND_CURSOR:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CURSOR_BLINK:
	rcall POINT_AT_CURSOR
	ld r16, Y
	cpi r16, black
	brne CURSOR_OFF
	lds r16, CURSOR_COLOR
	st Y, r16
	rjmp BLINK_DONE
CURSOR_OFF:
	clr r16
	st Y, r16
BLINK_DONE:
	rcall LOAD_DAMATRIX
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SEND_BOARD_INIT:
	ldi XH,HIGH(DAMATRIX)
	ldi XL,LOW(DAMATRIX)
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SEND_COLUMN:
	push r17

	ldi r17,3
NEXT_COLOR:
	ld r16,X+
	rcall SPI_SEND
	dec r17
	brne NEXT_COLOR
	rcall COLUMN_TRANSMITION

	pop r17
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COLUMN_TRANSMITION:
	lds r16, COLUMN       
	com r16
	call SPI_SEND
	cbi PORTB, SS
	sbi PORTB, SS
	cbi PORTB, SS 
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COLUMN_COUNTER:
	lds r16, COLUMN
	lsl r16
	cpi r16,0
	brne NO_DAMATRIX_RESET

	rcall SEND_BOARD_INIT
	ldi r16, 1
NO_DAMATRIX_RESET:
	sts COLUMN, r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;