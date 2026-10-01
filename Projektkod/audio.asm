	.equ	SPEAKER = PB1

	.equ	A0 = 142
	.equ	C = 119
	.equ	D = 106
	.equ	E = 95
	.equ	F = 89
	.equ	G = 80
	.equ	A = 71
	.equ	B = 63
	.equ	C2 = 60

	
; WIN is played when a level is finished.
WIN:
	.db		0, 119, 0, 119, 0, 119, 1, 95, 0, 95, 0, 95, 1, 80, 0, 80, 0, 80, 1, 60, 1, 1, 1, 0, 60, 63, 71, 80, 89, 95, 106, 119, 0, $FE

; FAILURE is played when the player tries to move in a way that's not allowed.
FAILURE:
	.db		119, 142, $FE

////// AUDIO_INIT //////
AUDIO_INIT:
	push	r16
	ldi		r16, (1<<MOSI)|(1<<SCK)|(1<<SS)|(1<<SPEAKER)
	out		DDRB, r16
	call	FAILURE_INIT
	pop		r16
	ret

////// FAILURE_INIT //////
; Initiates FAILURE_COUNTER to 0.
FAILURE_INIT:
	push	YH
	push	YL
	push	r16
	ldi		YH, HIGH(FAILURE_COUNTER)
	ldi		YL, LOW(FAILURE_COUNTER)
	ldi		r16, 0
	st		Y, r16
	pop		r16
	pop		YL
	pop		YH
	ret

////// FAILURE_COUNT //////
; Increases FAILURE_COUNTER with 1.
FAILURE_COUNT:
	push	YH
	push	YL
	push	r16
	ldi		YH, HIGH(FAILURE_COUNTER)
	ldi		YL, LOW(FAILURE_COUNTER)
	ld		r16, Y
	inc		r16
	st		Y, r16
	pop		r16
	pop		YL
	pop		YH
	ret

////// CHECK_FOR_FAILURE //////
; If FAILURE_COUNTER is more than 0 SEND_FAILURE i called.
CHECK_FOR_FAILURE:
	ldi		YH, HIGH(FAILURE_COUNTER)
	ldi		YL, LOW(FAILURE_COUNTER)
	ld		r18, Y
	tst		r18
	breq	NO_FAILURE
	call	SEND_FAILURE
	call	FAILURE_INIT
NO_FAILURE:
	ret

////// AUDIO_TIMER_INIT //////
; Sets COM1A0 to 1 in the TCCR1A register of TIMER1.
AUDIO_TIMER_INIT:
	ldi		r16, (1<<COM1A0)
	sts		TCCR1A, r16
	ret

////// AUDIO_TIMER_STOP //////
; Sets all bits to 0 in the TCCR1A register of TIMER1.
AUDIO_TIMER_STOP:
	ldi		r16, 0
	sts		TCCR1A, r16
	ret

////// SEND_BEEP //////
; Sends a beep.
SEND_BEEP:
	push	r16
	call	AUDIO_TIMER_INIT
	call	AUDIO_WAIT_SHORT
	call	AUDIO_TIMER_STOP
NO_BEEP:
	pop		r16
	ret

////// SEND_WIN //////
; Plays WIN.
SEND_WIN:
	push	ZH
	push	ZL
	push	YH
	push	YL
	push	r16
	push	r17
	ldi		ZH, HIGH(WIN*2)
	ldi		ZL, LOW(WIN*2)
	lpm		r17, Z+
SEND_WIN_NEXT:
	call	AUDIO_TIMER_INIT
	call	FIND_TONE
	call	AUDIO_WAIT_LONG
	lpm		r17, Z+
	cpi		r17, $FE
	brne	SEND_WIN_NEXT
	call	AUDIO_TIMER_STOP
	call	RESET_COUNTER
	pop		r17
	pop		r16
	pop		YL
	pop		YH
	pop		ZL
	pop		ZH
	ret

////// SEND_FAILURE //////
; Plays FAILURE.
SEND_FAILURE:
	push	ZH
	push	ZL
	push	YH
	push	YL
	push	r16
	push	r17
	ldi		ZH, HIGH(FAILURE*2)
	ldi		ZL, LOW(FAILURE*2)
	lpm		r17, Z+
SEND_FAILURE_NEXT:	
	call	FIND_TONE
	call	AUDIO_TIMER_INIT
	call	AUDIO_WAIT_LONG
	lpm		r17, Z+
	cpi		r17, $FE
	brne	SEND_FAILURE_NEXT
	call	AUDIO_TIMER_STOP
	call	RESET_COUNTER
	pop		r17
	pop		r16
	pop		YL
	pop		YH
	pop		ZL
	pop		ZH
	ret

////// FIND_TONE //////
; Finds the right tone.
FIND_TONE:
	cpi		r17, 142
	brne	NOT_A0
	call	SET_A0
	jmp		FIND_TONE_DONE
NOT_A0:
	cpi		r17, 119
	brne	NOT_C
	call	SET_C
	jmp		FIND_TONE_DONE
NOT_C:
	cpi		r17, 106
	brne	NOT_D
	call	SET_D
	jmp		FIND_TONE_DONE
NOT_D:
	cpi		r17, 95
	brne	NOT_E
	call	SET_E
	jmp		FIND_TONE_DONE
NOT_E:
	cpi		r17, 89
	brne	NOT_F
	call	SET_F
	jmp		FIND_TONE_DONE
NOT_F:
	cpi		r17, 80
	brne	NOT_G
	call	SET_G
	jmp		FIND_TONE_DONE
NOT_G:
	cpi		r17, 71
	brne	NOT_A
	call	SET_A
	jmp		FIND_TONE_DONE
NOT_A:
	cpi		r17, 63
	brne	NOT_B
	call	SET_B
	jmp		FIND_TONE_DONE
NOT_B:
	cpi		r17, 60
	brne	NOT_C2
	call	SET_C2
	jmp		FIND_TONE_DONE
NOT_C2:
	cpi		r17, 0
	brne	FIND_TONE_DONE
	call	AUDIO_TIMER_STOP
FIND_TONE_DONE:
	ret

////// SET_A0 //////
SET_A0:
	ldi		r16, HIGH(A0)
	sts		OCR1AH, r16
	ldi		r16, LOW(A0)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_C //////
SET_C:
	ldi		r16, HIGH(C)
	sts		OCR1AH, r16
	ldi		r16, LOW(C)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_D //////
SET_D:
	ldi		r16, HIGH(D)
	sts		OCR1AH, r16
	ldi		r16, LOW(D)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_E //////
SET_E:
	ldi		r16, HIGH(E)
	sts		OCR1AH, r16
	ldi		r16, LOW(E)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_F //////
SET_F:
	ldi		r16, HIGH(F)
	sts		OCR1AH, r16
	ldi		r16, LOW(F)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_G //////
SET_G:
	ldi		r16, HIGH(G)
	sts		OCR1AH, r16
	ldi		r16, LOW(G)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_A //////
SET_A:
	ldi		r16, HIGH(A)
	sts		OCR1AH, r16
	ldi		r16, LOW(A)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// SET_B //////
SET_B:
	ldi		r16, HIGH(B)
	sts		OCR1AH, r16
	ldi		r16, LOW(B)
	sts		OCR1AL, r16
	call	RESET_TIMER_LOW
	ret

////// SET_C2 //////
SET_C2:
	ldi		r16, HIGH(C2)
	sts		OCR1AH, r16
	ldi		r16, LOW(C2)
	sts		OCR1AL, r16
	call	RESET_TIMER_LOW
	ret

////// RESET_TIMER //////
; Timer1 is set to count from 69.
RESET_TIMER:
	ldi		r16, HIGH(69)
	sts		TCNT1H, r16
	ldi		r16, LOW(69)
	sts		TCNT1L, r16
	ret

////// RESET_TIMER_LOW //////
; Timer1 is set to count from 0.
RESET_TIMER_LOW:
	ldi		r16, HIGH(0)
	sts		TCNT1H, r16
	ldi		r16, LOW(0)
	sts		TCNT1L, r16
	ret

////// RESET_COUNTER //////
; Timer1 is set to count to the value in COUNTER.
RESET_COUNTER:
	ldi		r16, HIGH(COUNTER)
	sts		OCR1AH, r16
	ldi		r16, LOW(COUNTER)
	sts		OCR1AL, r16
	call	RESET_TIMER
	ret

////// AUDIO_WAIT_SHORT //////
AUDIO_WAIT_SHORT:
	push	r19
	push	r18
	push	r17
	ldi		r19, 9
AWS_LOOP_3:
	ldi		r18, 0
AWS_LOOP_2:
	ldi		r17, 0
AWS_LOOP_1:
	dec		r17
	brne	AWL_LOOP_1
	dec		r18
	brne	AWL_LOOP_2
	dec		r19
	brne	AWL_LOOP_3
	pop		r17
	pop		r18
	pop		r19
	ret

////// AUDIO_WAIT_LONG //////
AUDIO_WAIT_LONG:
	push	r19
	push	r18
	push	r17
	ldi		r19, 10
AWL_LOOP_3:
	ldi		r18, 0
AWL_LOOP_2:
	ldi		r17, 0
AWL_LOOP_1:
	dec		r17
	brne	AWL_LOOP_1
	dec		r18
	brne	AWL_LOOP_2
	dec		r19
	brne	AWL_LOOP_3
	pop		r17
	pop		r18
	pop		r19
	ret

