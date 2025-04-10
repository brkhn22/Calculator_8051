ORG 0000H

MOV P1, #92H      ; Set Port 1 as input
MOV P2, #03H      ; Set Port 2 as input
MOV P3, #00H      ; Set Port 3 as output 1
MOV P0, #00H	  ; Set Port 0 as output 0

; === Extract Lower and Upper BCD Digits ===
MOV A, P1          ; Read BCD inputs (P1)
MOV B, A           ; Store a copy in B

ANL A, #0FH        ; Extract Lower nibble (BCD A)
MOV R0, A          ; Store Lower BCD in R0

MOV A, B           ; Restore original value
SWAP A             ; Swap nibbles (Upper nibble moves to lower)
ANL A, #0FH        ; Extract Upper nibble (BCD B)
MOV R1, A          ; Store Upper BCD in R1

MOV A, P2          ; Read operation code from P2
ANL A, #03H        ; Ensure only lower 2 bits are used

; === Perform the Required Operation ===
CJNE A, #00H, CHECK_SUB   ; If operation code is 00, do addition
MOV A, R0
ADD A, R1
CALL BCD_CONVERT

CHECK_SUB:
CJNE A, #01H, CHECK_MUL   ; If operation code is 01, do subtraction
MOV A, R1
SUBB A, R0
JC MINUS_VALUE
CALL BCD_CONVERT
MINUS_VALUE:
CLR C
MOV B, A
MOV A, #0FFH
SUBB A, B
ADD A, #01H
SETB P0.0
CALL BCD_CONVERT

CHECK_MUL:
CJNE A, #02H, CHECK_DIV   ; If operation code is 10, do multiplication
MOV A, R0
MOV B, R1
MUL AB
CALL BCD_CONVERT

CHECK_DIV:
CJNE A, #03H, INVALID     ; If operation code is 11, do division
MOV A, R0
JNZ DIVISION_ABLE
SJMP INVALID
DIVISION_ABLE:
MOV A, R1
MOV B, R0

DIV AB
SWAP A
ADD A, B
MOV R3, A
CALL DISPLAY_SIMPLE_RESULT

INVALID:
CLR C
MOV P3, #00H  ; Display error code if invalid operation
MOV P0, #00H
SJMP $

; === Convert the Result into Tens and Ones Digits ===
BCD_CONVERT:
    ; Store result in R3
    	MOV R3, A
	SUBB A, #0AH        ; Compare A with 0AH (subtracts A from 0AH)
	JC DISPLAY_SIMPLE_RESULT  ; Jump if carry flag is set (A >= 0AH)
    	MOV A, #00H
    	MOV R2, A
    	MOV R1, A
    	Loop_Start:
    		MOV A, R3
    		SUBB A, #01H
    		MOV R3, A
    		JC Exit
    		MOV A, R1
    		ADD A, #01H
    		MOV R1, A
		SUBB A, #0AH      ; Subtract #0AH from A with borrow
		CJNE A, #00H, Loop_Start   ; Jump to LoopStart if A is not equal to #0AH
   		MOV R1, A
   		MOV A, R2
    		ADD A, #01H
    		MOV R2, A
    		SJMP Loop_Start
    	Exit:
    	CLR C
    	MOV A, R1
    	MOV R4, A
    	MOV A, R2
    	SWAP A
    	ORL A, R4
    	MOV R4, A
    	MOV P3, A
    	CALL LED_DISPLAY
    
DISPLAY_SIMPLE_RESULT:
	CLR C
	MOV P3, R3
	CALL LED_DISPLAY

LED_DISPLAY:
	MOV A, P3
	SWAP A
	ANL A, #0FH
	MOV R2, A
	MOV A, P3
	ANL A, #0FH
	MOV R3, A
	
	MOV A, R3
	CALL LED_NUMBER_P3
	MOV A, R2
	CALL LED_NUMBER_P0
	
	CALL DELAY

LED_NUMBER_P3:
		CJNE A, #00H, CHECK_ONE_P3
		MOV P3, #11110110B
	CHECK_ONE_P3:	CJNE A, #01H, CHECK_TWO_P3
		MOV P3, #01000100B
	CHECK_TWO_P3:	CJNE A, #02H, CHECK_THREE_P3
		MOV P3, #10101110B
	CHECK_THREE_P3:	CJNE A, #03H, CHECK_FOUR_P3
		MOV P3, #11001110B
	CHECK_FOUR_P3:	CJNE A, #04H, CHECK_FIVE_P3
		MOV P3, #01011100B
	CHECK_FIVE_P3:	CJNE A, #05H, CHECK_SIX_P3
		MOV P3, #11011010B
	CHECK_SIX_P3:	CJNE A, #06H, CHECK_SEVEN_P3
		MOV P3, #11111010B
	CHECK_SEVEN_P3:	CJNE A, #07H, CHECK_EIGHT_P3
		MOV P3, #01000110B
	CHECK_EIGHT_P3:	CJNE A, #08H, CHECK_NINE_P3
		MOV P3, #11111110B
	CHECK_NINE_P3:	CJNE A, #09H, POSITIVE_NUMBER_P3
		MOV P3, #11011110B
	POSITIVE_NUMBER_P3:
	MOV A, P3
	CPL A
	MOV P3, A
	RET

LED_NUMBER_P0:
		JNB P0.0, CHECK_ZERO
		MOV P0, #00001000B
		SJMP POSITIVE_NUMBER
	CHECK_ZERO:	CJNE A, #00H, CHECK_ONE
		MOV P0, #11110110B
	CHECK_ONE:	CJNE A, #01H, CHECK_TWO
		MOV P0, #01000100B
	CHECK_TWO:	CJNE A, #02H, CHECK_THREE
		MOV P0, #10101110B
	CHECK_THREE:	CJNE A, #03H, CHECK_FOUR
		MOV P0, #11001110B
	CHECK_FOUR:	CJNE A, #04H, CHECK_FIVE
		MOV P0, #01011100B
	CHECK_FIVE:	CJNE A, #05H, CHECK_SIX
		MOV P0, #11011010B
	CHECK_SIX:	CJNE A, #06H, CHECK_SEVEN
		MOV P0, #11111010B
	CHECK_SEVEN:	CJNE A, #07H, CHECK_EIGHT
		MOV P0, #01000110B
	CHECK_EIGHT:	CJNE A, #08H, CHECK_NINE
		MOV P0, #11111110B
	CHECK_NINE:	CJNE A, #09H, POSITIVE_NUMBER
		MOV P0, #11011110B
	POSITIVE_NUMBER:
	MOV A, P0
	CPL A
	MOV P0, A
	RET

DELAY:

    CLR C
    MOV R7, #0FFH
    DJNZ R7, $
END
