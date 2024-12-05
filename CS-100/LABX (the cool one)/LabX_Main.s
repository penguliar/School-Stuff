; CS100_LabX_Main
; Due Date: 12/4/2024
; Student Name: Aeden Brookshire
; Section: 

; Author: 
; © 2020 DigiPen, All Rights Reserved.
    
	GET LabX_Data.s             		; Get/include the data file
	GLOBAL __main               		; Global main function
	AREA LabX_Main, CODE, READONLY	; Area of code that is read only
	ALIGN 2                     		; Align the data boundary to a multiple of 2
	ENTRY                       		; Entry into the code segment

;;;;;;;; subroutines ;;;;;;;;;;;

;---------------------------------  
; Subroutine: _setbits
; Sets bits in memory
; Eg. passing "1001" in R1 will set bits at position 0 and 3 in R0
; Inputs: 	R0 = address of value to modify
;			      R1 = bitmask
_setbits
	PUSH {LR}
	LDR R2, [R0]	; loads the contents of memory referenced in R0 into R2
	ORR R2, R1		; bit-wise or
	STR R2, [R0]	; Stores value of R2 into memory referenced in R0
	POP {LR}
	BX LR

;---------------------------------  
; Subroutine: _clearbits	
; Clears bits in memory
; Eg. passing "1001" in R1 will clear bits at position 0 and 3 in R0
; Inputs: 	R0 = address of value to modify
;			R1 = bitmask
_clearbits
	PUSH {LR}
	LDR R2, [R0]	; loads the contents of memory referenced in R0 into R2
	MVN R3, R1		; (move not) inverts R1 and puts it in R3
	AND R2, R3		; preforms an and operation on R2 and R3 and stores in R2
	STR R2, [R0]	; Stores value of R2 into memory referenced in R0
	POP {LR}
	BX LR

;--------------------------------- 
;Subroutine: delay 
; waits for #COUNT1 ticks to complete
delay 
	MOV R10, #COUNT1
L
	SUBS R10, R10, #1
	CMP R10, #0 
	BNE L
	BX LR

;---------------------------------  
; Subroutine: output_pins_config 
;Sets up output pins 
;Inputs:None, Outputs:None

output_pins_config 
	
  PUSH { R4-R11, LR } ; stack preserved registers and link register

   ;STUDENT CODE STARTS HERE
   
   ; step 2a
   SETBITS RCGCPWM, 2_1 ; Set peripheral clock and enable MODULE 0
   
; Turn on port B and wait for response   
; step 2b
   SETBITS RCGCGPIO, 2_10
waitforbloop ; start of loop (wait for port B to B set)
	LDR R0, =RCGCGPIO
	LDR R1, [R0]
	CMP R1, #2_1
    BNE delay
	BNE waitforbloop ; loop if port B isn't set

; step 2c-2e
	SETBITS GPIOBDEN, 0x40
	SETBITS GPIOBDIR, 0x40
	SETBITS GPIOBAFSEL, 0x40
	SETBITS GPIOBPCTL, 0x20000000
	
   ;STUDENT CODE ENDS HERE 
   
    ; Return back to the calling subroutine.
    POP { R4-R11, LR }
    BX LR

;---------------------------------  
; Subroutine: pwm_setup 
;Configures PWM port PB7 with its initial frequency 
;Inputs:None, Outputs:Sound on the buzzer

pwm_setup 
	
  PUSH { R4-R11, LR } ; stack preserved registers and link register


   ;STUDENT CODE STARTS HERE 
   
   
   
   ;STUDENT CODE ENDS HERE 

	; Return back to the calling subroutine.
    POP { R4-R11, LR }
    BX LR	
	

__main 

   ;STUDENT CODE STARTS HERE 
   
   BL output_pins_config
   
   ;STUDENT CODE ENDS HERE 
	

	END
	