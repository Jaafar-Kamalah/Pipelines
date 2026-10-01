;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.equ  MOSI = PB3
	.equ SCK = PB5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPI_INIT:
	push r16

	ldi r16, (1<<MOSI)|(1<<SCK)|(1<<SS)
	out DDRB, r16                          ; Sets MOSI, SCK, SS as output
	ldi r16, (1<<SPE)|(1<<MSTR)|(1<<SPR0)|(1<<SPR1)
	out SPCR, r16                          ; Enable SPI, Master, fck/16

	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPI_SEND:
	push r16

	out SPDR, r16
SPI_TRANSMIT_WAIT:
	in r16, SPSR
	sbrs r16, SPIF
	rjmp SPI_TRANSMIT_WAIT 

	pop r16
	ret 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;