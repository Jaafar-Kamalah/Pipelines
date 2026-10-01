/////////////JOY_RIGHT & L2 INPUTS/////////////
KEY_READ:
	rcall KEY
	tst r16
	brne KEY_READ              ; old key still pressed
KEY_WAIT_FOR_PRESS:
	rcall FAILURE_INIT         ; resets failure sound flag 
	rcall KEY   
	rcall CHECK_FOR_FAILURE    ; plays failure sound if block is triggered        
	mov r17,r16
	tst r16	
	breq KEY_WAIT_FOR_PRESS	   ; no key pressed
	cpi r16, 5
	breq KEY_READ              ; block triggered
	rcall WAIT
	rcall KEY                 
	cp r16,r17                 
	brne KEY_WAIT_FOR_PRESS    ; kontaktstuds
	;new key value available
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KEY:
	ldi r16, $27                     ; L2 BUTTON
	rcall TWI_RECEIVE
	andi r16,0b00111111              ; mask out L2
	cpi r16,$37                      ; $37 == L2 pressed
	brne NOT_L2
	ldi r16, 10                      ; 10 is key for select in KEY_SEND
	rjmp KEY_EXIT
NOT_L2:
	clr r16

	ldi	r16,(1<<REFS0)|(1<<ADLAR)|0  ; RIGHT JOYSTICK X AXIS
	sts ADMUX,r16
	rcall ADC_READ8
	rcall KEY_CONVERT                ; 8 / -8 key if JOY == right/left
	cpi r16, 0
	breq VERTICAL_AXIS
	rcall HORISONTAL_BORDER_BLOCK
	rjmp KEY_DONE

VERTICAL_AXIS:
	ldi	r16,(1<<REFS0)|(1<<ADLAR)|1  ; RIGHT JOYSTICK Y AXIS
	sts ADMUX,r16
	rcall ADC_READ8
	rcall KEY_CONVERT
	asr r16
	asr r16
	asr r16
	neg r16                          ; 1 / -1 key if JOY == down / up
	rcall VERTICAL_BORDER_BLOCK

KEY_DONE:
	tst r16
	breq KEY_EXIT                    ; Skip block_checks if nothing pressed
	rcall SELECT_BLOCK               ; Block if selected and moving into other color
	rcall CONNECTION_BLOCK         ; Block if connected and moving in direction other than back
KEY_EXIT:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KEY_CONVERT:
	cpi r16, 1
	brlo LEFT
	cpi r16, 200
	brsh RIGHT
	ldi r16,0
	rjmp KEY_CONVERT_DONE
RIGHT:
	ldi r16, 8                ; right 
	rjmp KEY_CONVERT_DONE
LEFT:
	ldi R16, -8               ; left
KEY_CONVERT_DONE:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VERTICAL_BORDER_BLOCK:
	push r17                  ; r17 used for kontaktstudshantering
	lds r17, CURSOR_POSITION
	cpi r16, -1               ; Up direction: block if on 0,8,16,24,32,40,48,56
	breq BLOCK_NEXT_ROW
	cpi r16, 1                ; Down direction: block if on 7,15,23,31,39,47,55,63
	brne VBB_EXIT             
	inc r17                   ; Make down direction divisible by 8

BLOCK_NEXT_ROW:
	tst r17
	breq VBB_BLOCK           ; Block if r17 is divisible with 8
	brmi VBB_EXIT
	subi r17, 8
	rjmp BLOCK_NEXT_ROW

VBB_BLOCK:
	ldi r16, 5               ; 5 == flag for block
	rcall FAILURE_COUNT      ; Failure sound counter
VBB_EXIT:
	pop r17
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HORISONTAL_BORDER_BLOCK:
	push r17                 ; r17 used for kontaktstudshantering
	lds r17, CURSOR_POSITION
	add r17, r16
	cpi r17, 0
	brlo HBB_BLOCK
	cpi r17, 64
	brsh HBB_BLOCK
	rjmp HBB_EXIT

HBB_BLOCK:
	ldi r16, 5              ; 5 == flag for block
	rcall FAILURE_COUNT     ; Failure sound counter 
HBB_EXIT:
	pop r17
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT_BLOCK:
	push r17              ; r17 used for kontaktstudshantering

	lds r17, SELECT_FLAG
	cpi r17, $FF
	brne SB_EXIT          ; exit if nothing selected

	rcall POINT_AT_CURSOR
	add Yl, r16
	ld r17, Y
	andi r17, 7
	lds r18, CURSOR_COLOR
	andi r18, 7

	cp r17, r18
	breq SB_EXIT         ; do not block if moving to same color tile
	cpi r17, black
	breq SB_EXIT         ; do not block if moving to black tile

SB_BLOCK:
	ldi r16, 5           ; 5 == flag for block
	rcall FAILURE_COUNT  ; Failure sound counter 

SB_EXIT:	
	pop r17
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONNECTION_BLOCK:    
	push r17

	lds r17, SELECT_FLAG
	cpi r17, $FF
	brne SB_EXIT             ; exit if nothing selected

	lds r17, CURSOR_COLOR
	sbrc r17, 4            
	rjmp CB_EXIT             ; exit if cursor is on line and not point
	
	rcall POINT_AT_CURSOR
	add YL, r16
	ld r18, Y
	andi r18, 7
	andi r17, 7
	cp r18, r17           
	breq CB_EXIT             ; exit if moving back onto line of same color

	sub YL, r16             
	ldi ZL, LOW(ADJACENT*2)
	ldi ZH, HIGH(ADJACENT*2)
NEXT_ADJACENT:
	lpm r18, Z+              ; check all directions of cursor

	tst r18
	breq CB_EXIT             ; if no lines attached to point do not block 

	add YL, r18
	ld r19, Y
	andi r19, 7
	cp r19, r17              ; if r19 == r17 this point has a line attached
	breq CB_BLOCK 
	sub YL, r18
	rjmp NEXT_ADJACENT


CB_BLOCK:
	ldi r16, 5              ; 5 == flag for block
	rcall FAILURE_COUNT     ; Failure sound counter 
CB_EXIT:	
	pop r17
	ret