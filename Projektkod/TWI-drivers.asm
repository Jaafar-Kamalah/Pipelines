/////////////////////MAIN ROUTINES/////////////////////
TWI_SPEED_INIT:                   ; Körs en gång i "COLD"
	ldi r16,$0F                   ; Bitrate speed (FF is slowest)
	sts TWBR,r16
	ret
;;;;;;;;;;;;;;;|r16-adress||r17-send|;;;;;;;;;;;;;;;;;;
TWI_SEND:
	rcall TWI_OPEN                ; Start-tillstånd
	lsl r16                       ; WRITE bit i adressen
	rcall TWI_WRITE               ; Skickar address
	mov r16,r17                   
	rcall TWI_WRITE               ; Skickar data
	rcall TWI_CLOSE               ; Stop-tillstånd
	ret
;;;;;;;;;;;;;|r16-adress||r16-recieve|;;;;;;;;;;;;;;;;;
TWI_RECEIVE:
	rcall TWI_OPEN                ; Start-tillstånd
	lsl r16
	ori r16,1                     ; READ bit i adressen
	rcall TWI_WRITE               ; Skickar adress
	rcall TWI_READ                ; Läser in data
	rcall TWI_CLOSE               ; Stop-tillstånd
	ret
/////////////////////HELP ROUTINES/////////////////////
TWI_OPEN:
	push r16
	ldi r16,(1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
	sts TWCR,r16
	rcall WAIT_FOR_TWINT
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TWI_WRITE:
	sts TWDR,r16
	ldi r16,(1<<TWINT)|(1<<TWEN)
	sts TWCR,r16
	rcall WAIT_FOR_TWINT
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TWI_READ:
	ldi r16,(1<<TWINT)|(1<<TWEN)
	sts TWCR,r16
	rcall WAIT_FOR_TWINT
	lds r16,TWDR
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TWI_CLOSE:
	push r16
	ldi r16,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
	sts TWCR,r16
	pop r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WAIT_FOR_TWINT:
	lds r16,TWCR
	sbrs r16,TWINT
	rjmp WAIT_FOR_TWINT
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;