;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JOY_RIGHT_INIT:	
	ldi r16,(1<<ADEN)|7              ; AD-enable, 128 prescaler
	sts ADCSRA,r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADC_READ8:
	lds r16,ADCSRA
	ori r16,(1<<ADSC)      ; Starta omvandling
	sts ADCSRA,r16
ADC_BUSY:
	lds r16,ADCSRA
	sbrc r16,ADSC          ; Skip om omvandling klar
	rjmp ADC_BUSY
	;Omvanlding klar
	lds r16, ADCH		   ; 0-255 steg, 1.9mV/steg
	ret