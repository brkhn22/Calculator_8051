ORG 0000H

MOV P1, #87H      ; Set Port 1 as input (BCD numbers)
MOV P2, #01H      ; Set Port 2 as input (Operation code)
MOV P3, #00H      ; Set Port 3 as output (Seven-segment display)

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
CLR C
SUBB A, R0
CALL BCD_CONVERT

CHECK_MUL:
CJNE A, #02H, CHECK_DIV   ; If operation code is 10, do multiplication
MOV A, R0
MOV B, R1
MUL AB
CALL BCD_CONVERT

CHECK_DIV:
CJNE A, #03H, INVALID     ; If operation code is 11, do division
MOV A, R1
MOV B, R0
DIV AB
SWAP A
ADD A, B
MOV R3, A
CALL DISPLAY_SIMPLE_RESULT

INVALID:
MOV P3, #0FFH  ; Display error code if invalid operation
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
    	
    	MOV A, R1
    	MOV R4, A
    	MOV A, R2
    	SWAP A
    	ORL A, R4
    	MOV R4, A
    	MOV P3, A
    	CALL DELAY
    
DISPLAY_SIMPLE_RESULT:
	MOV P3, R3
	CALL DELAY

DELAY:
    CLR C
    MOV R7, #0FFH
    DJNZ R7, $
END
