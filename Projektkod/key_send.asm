/////////////JOY_RIGHT & L2 OUTPUT/////////////
KEY_SEND:
	cpi r16, 10
	breq SELECT_KEY
	rcall JOY_SEND
	rcall SHORTCUT           ; If adjacent to two lines of same color make shortcut
	rcall SHORTCUT           ; Check again (in cases where three lines adjacent two shortcuts can be made)
	rjmp SEND_KEY_DONE
SELECT_KEY:  
	rcall SELECT_SWITCH
	rcall CHECK_LEVEL_DONE        ; Continiues to next level if current level done
SEND_KEY_DONE:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JOY_SEND:
	rcall SEND_BEEP               ; Sound for allowed movement
	rcall POINT_AT_CURSOR
	lds r17, CURSOR_POSITION
	sts PREV_CURSOR_POSITION, r17 ; Update previous cursor position

	lds r18, CURSOR_COLOR
	cpi r18, white                
	brne KEEP_CURSOR_COLOR        ; If cursor white == no color is under cursor
	ldi r18, black                ; so previous color should be black

KEEP_CURSOR_COLOR:
	st Y, r18                     ; else previous color should be CURSOR_COLOR
	add r17, r16
	sts CURSOR_POSITION, r17      ; update CURSOR_POSITION

SKIP_CURSOR_SAVE:
	rcall CURSOR_SEND
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT_SWITCH:
	lds r16, SELECT_FLAG
	tst r16
	brne SELECT_HIGH       ; Unselecting is always allowed

	lds r17, CURSOR_COLOR
	cpi r17, white
	breq SELECT_SEND_DONE  ; Selecting is not allowed if cursor is white

	sbrs r17, 3
	rjmp SELECT_SEND_DONE ; Selecting is not allowed on unselectable points
	
	sbrs r17, 4
	rcall RESET_COLOR     ; Remove all lines if selecting a startpoint
SELECT_HIGH:
	com r16
	sts SELECT_FLAG, r16
SELECT_SEND_DONE:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET_COLOR:
	push r16
	lds r18, CURSOR_COLOR
	andi r18, 7
	ldi r16, 64          ; loop counter
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)

RC_NEXT_COLOR:
	ld r17, Y
	andi r17, 7
	cp r17, r18  
	brne RC_SKIP         ; if not same color do not change
	ld r17, Y
	ori r17, 8           ; make selectable
	sbrc r17, 4
	clr r17              ; if line clear
	
	st Y, r17
RC_SKIP:
	inc YL               ; next board position
	dec r16
	brne RC_NEXT_COLOR

	pop r16
	ret
///////////////CURSOR -> BOARD/////////////////
CURSOR_SEND:
	rcall POINT_AT_CURSOR

	lds r17, SELECT_FLAG
	cpi r17, $FF
	brne NOT_SELECTED
	rcall SELECT_SEND             ; if moving line
	rjmp COLORED_CURSOR

NOT_SELECTED:
	ld r16, Y                
	cpi r16, black                ; if cursor on black then CURSOR_COLOR = white
	brne COLORED_CURSOR           ; else CURSOR_COLOR = color cursor is on
	ldi r16, white                
COLORED_CURSOR:
	sts CURSOR_COLOR, r16         
	st Y, r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT_SEND:
	rcall PREVIOUS_VALUE_SEND_INIT
	rcall PREVIOUS_VALUE_SEND
	rcall CURR_VALUE_SEND
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PREVIOUS_VALUE_SEND_INIT:
	ld r17, Y                       ; Current cursor value (curr)
	lds r16, CURSOR_POSITION
	sub YL, r16                     
	lds r16, PREV_CURSOR_POSITION
	add YL, r16                     
	ld r16, Y                       ; Previous cursor value (prev)
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PREVIOUS_VALUE_SEND:
	andi r16, 7                     ; Special case 1
	cp r17, r16                     ; if (curr = unselectable, non line) and (prev = same color as curr) 
	breq PREV_POS_REMOVED           ; delete prev

	                                ; Special case 2
	ld r18, Y                       ; prev
	ori r16, 8
	cp r18, r16                     ; if prev not a selectable non line
	brne NOT_SPECIAL_CASE           ; jump out

	andi r16, 7
	ori r16, 16
	cp r17, r16                     ; else if curr is unselectable line
	breq PVS_EXIT                   ; do not change prev

NOT_SPECIAL_CASE:
	ld r16, Y 
	andi r17, 0b11110111            ;  curr value with masked selectable flag
	andi r16, 0b11110111            ;  prev value with masked selectable flag
	cp r17, r16                     ;  If (curr = line) and (prev = line of same color) delete prev
	brne PREV_POS_UNSELECTABLE      ;  else make prev unselectable

PREV_POS_REMOVED:
	clr r16                         
PREV_POS_UNSELECTABLE:
	andi r16, 0b11110111            
	st Y, r16
PVS_EXIT:
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CURR_VALUE_SEND:
	rcall POINT_AT_CURSOR
	lds r16, CURSOR_COLOR 
	ori r16, 16            ; line flag

	ld r17, Y
	cpi r17, black
	breq CURR_VALUE_EXIT   ; if curr is black or a line
	sbrs r17, 4            ; r16 = CURSOR_COLOR + line flag set
	andi r16, 0b00001111   ; else r16 = CURSOR_COLOR
CURR_VALUE_EXIT:
	ret                    ; r16 is later set to new CURSOR_COLOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHORTCUT:
	lds r16, CURSOR_POSITION
	push r16

	lds r17, SELECT_FLAG   
	cpi r17, $FF
	brne SHORTCUT_EXIT              ; exit if nothing selected

	rcall SHORTCUT_CHECK_INIT
	rcall SHORTCUT_CHECK

SHORTCUT_EXIT:
    pop r16
	sts CURSOR_POSITION, r16   ; Restore CURSOR_POSITION to original value
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHORTCUT_CHECK_INIT: 
	ldi ZL, LOW(ADJACENT*2)   ; 8, -8, 1, -1, 0
	ldi ZH, HIGH(ADJACENT*2)

	lds r18, CURSOR_COLOR
	andi r18, 7

	clr r19                   ; matches counter
	rcall POINT_AT_CURSOR     ; Y pointer pointing at cursor position
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHORTCUT_CHECK:    
	lpm r16, Z+                 ; 8, -8, 1, -1, 0
	tst r16 
	breq SC_DONE

	sts CURSOR_POSITION, YL

	rcall VERTICAL_BORDER_BLOCK
	rcall HORISONTAL_BORDER_BLOCK
	cpi r16,5
	brne NOT_OUTSIDE_BORDERS
	clr r16

NOT_OUTSIDE_BORDERS:
	add YL, r16
	ld r17, Y
	andi r17, 15    ; line flag masked out
	sub YL, r16

	cp r17, r18     ; if r17 is CURSOR_COLOR with or without line flag set -> count a match
	brne NOT_MATCH
MATCH:
	inc r19         ; Match counter
NOT_MATCH:
	rjmp SHORTCUT_CHECK

SC_DONE:                 ; (at least one match once color selected) (impossible to have 4 or more matches)
	sbrc r19, 1          ; if there are 2 or 3 matches send shortcut
	rcall SHORTCUT_SEND    
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHORTCUT_SEND:
	rcall SHORTCUT_SEND_INIT

SHORTCUT_SEND_LOOP:
	rcall FIND_SHORTCUT_LINE
	cpi r16, $FF
	breq SHORTCUT_SEND_EXIT   ; if shortcut is done

	clr r17                   
	st Y, r17                 ; delete tail   
	inc r20                   ; increase deletion counter

	add YL, r21               ; move to the next line segment
	clr r21
	rjmp SHORTCUT_SEND_LOOP
SHORTCUT_SEND_EXIT:
	sts PREV_CURSOR_POSITION, YL ; PREV_CURSOR_POSITION has to be uptadet since it otherwise points at a point that now is black
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHORTCUT_SEND_INIT:
	ldi YH, HIGH(BOARD)
	ldi YL, LOW(BOARD)
	lds r16, PREV_CURSOR_POSITION
	add YL, r16                    ; Y pointer pointing at previous cursor position

	lds r19, CURSOR_POSITION
	clr r20                        ; deletion counter
	clr r21                        ; next line segment
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FIND_SHORTCUT_LINE:
	sts CURSOR_POSITION, YL      ; update CURSOR_POSITION so BLOCK routines work
	ldi ZL, LOW(ADJACENT*2)     
	ldi ZH, HIGH(ADJACENT*2)     ; 8, -8, 1, -1, 0

SS_NEXT_ADJACENT:
	lpm r16, Z+                  ; 8, -8, 1, -1, 0
	tst r16
	breq FSL_EXIT
      
	rcall VERTICAL_BORDER_BLOCK
	rcall HORISONTAL_BORDER_BLOCK
	cpi r16,5                      ; if adjacent value moves Y pointer over board borders
	breq SS_NEXT_ADJACENT          ; skip value

	add YL, r16
	ld r17, Y
	andi r17, 15

	cpi r20, 2                    ; if deletion counter >= 2, look for starting position
	brlo NOT_END_OF_LINE
	cp YL, r19                    ; if YL on original cursor position
	brne NOT_END_OF_LINE
	sub YL, r16
	ldi r16, $FF                  ; flag for if to exit SHORTCUT_SEND_LOOP
	rjmp FSL_EXIT

NOT_END_OF_LINE:
	sub YL, r16
	cp r17, r18                  ; if r17 == CURSOR_COLOR with masked out flags
	brne SKIP_DELETER
	mov r21, r16                 ; next line segment
SKIP_DELETER:
	rjmp SS_NEXT_ADJACENT
FSL_EXIT:
	ret