;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WAIT:
	push ZL
	push ZH
	clr ZL
	clr ZH
WAIT_LOOP:
	adiw ZL,4             ; ca 16 millisekunder
	brne WAIT_LOOP
	pop ZH
	pop ZL
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LONG_WAIT:
	push r16
	ldi r16,120
LONG_WAIT_LOOP:
	rcall WAIT
	dec r16              ; ca 0.492 sekunder
	brne LONG_WAIT_LOOP
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;