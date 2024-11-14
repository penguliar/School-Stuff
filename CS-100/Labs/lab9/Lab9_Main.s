; CS 100 Lab 9
; Due Date:
; Student Name:	
; Section: 

; Title: "Lab9_Main"
; © 2021 DigiPen, All Rights Reserved.
	
	GET Lab9_Data.s             		; Get/include the data file
	GLOBAL __main               		; Global main function
	AREA Lab9_Main, CODE, READONLY		; Area of code that is read only
	ALIGN 2                     		; Align the data boundary to a multiple of 2
	ENTRY                       		; Entry into the code segment

;======Bit Methods-Nothing-new-here===================;
;---------------------------------  
; _SETBITS: Sets bits in memory (passing "1001" in R1 will set bits at position 0 and 3 in R0)
_SETBITS ; Turn on bits at address R0 specified by 1's in R1 
    PUSH {R4-R11, LR}
	LDR R4, [R0]
	ORR R4, R1
	STR R4, [R0]
    POP {R4-R11, LR}
  BX LR

;--------------------------------- 
; _CLEARBITS: Clears bits in memory (passing "1001" in R1 will clear bits at position 0 and 3 in R0)
_CLEARBITS ; Turn off bits at address R0 specified by 1's in R1
    PUSH {R4-R11, LR}
	LDR R4, [R0]
	MVN R3, R1
	AND R4, R3
	STR R4, [R0]
    POP {R4-R11, LR}
  BX LR	
;----------------------------------
_DELAY ; Loop R0 times
    PUSH {R4-R11, LR}
	MOV R10, R0
LOOPDELAY
	SUBS R10, R10, #1
	CMP R10, #0 
	BNE LOOPDELAY
    POP {R4-R11, LR}
  BX LR

;====================ADC Subroutines=======================;
;---------------------------------  
; Loops until ADC value is ready to be read
; Inputs: R0 = address of value to read
; Outputs: None
_wait_adc
	PUSH {LR, R4-R11}
_wait_for_adc_loop; don't keep pushing registers.
; STUDENT CODE HERE ****SUBROUTINE STEP A****
	LDR R4, [R0]
	SUBS R4, #2_1
	BNE _wait_for_adc_loop
; END STUDENT CODE
	POP {LR, R4-R11}
	BX LR
	
	
;---------------------------------  
; Reads the last 3 nibbles of the register.
; Inputs: R0 = address of value to read
; Outputs: Masked result of ADC in R0
_read_adc
	PUSH {LR, R4-R11}
; STUDENT CODE HERE ****SUBROUTINE STEP B****
	LDR R4, [R0]
	LDR R5, =0xFFF
	AND R4, R5
	MOV R0, R4

	
; END STUDENT CODE
	POP {LR, R4-R11}	
	BX LR


;====================SETUP=======================;
;---------------------------------  
; Subroutine: ports_activation 
; Description: Initializes output Ports so they are set up for use. If we don't
;   do this, the pin won't work. 

_led_pins_activation 
    PUSH { R4-R11, LR } ; stack preserved registers and link register

      SETBITS RCGCGPIO, 2_10011     ; A(1), B(2), C(4), D(8), E(10), F(20), we're only turning on ports A+B+E
      SETBITS GPIOBDEN, 0xFF        ;Configure used pins of Port B as digital
        
    POP { R4-R11, LR } ; Restore the link register and R4-R11 in case we changed them here
  BX LR;Return back to the calling subroutine.


;---------------------------------  
; Subroutine: led_initialization
; Description: Initializes our LEDs so they are set up for output. If we don't
;   do this, we will not be able to correctly turn them on or off later.

_led_initialization
    PUSH { R4-R11, LR } ; stack preserved registers and link register
      SETBITS GPIOBDIR, 0xFF         ; MAKE SURE ALL PORTB PINS (PB0-PB7) ARE SET UP FOR OUTPUT
      CLEARBITS GPIOBDATA_RW, 0x00   ; MAKE SURE ALL PORTB PINS (PB0-PB7) START WITH 0 ON THE OUTPUT	
    POP { R4-R11, LR }; restore the preserved registers and link register
  BX LR; Return back to the calling subroutine.

;---------------------------------  
; Subroutine: adc_initialization
; Description: Initializes our ADC Module and Sequencer so they are set up for analog input. 

_adc_initialization
    PUSH { R4-R11, LR } ; stack preserved registers and link register

;---ADC Module Initialization (PP 817): this is copy-pasted-edited-- see lecture------------
	SETBITS RCGCADC, 0x1             ;1.Enable the ADC clock - RCGCADC (PP 352).
                                     ;2.We did this in Step 3A -Enable RCGCGPIO register FOR PORT E(see page 340).
                                     ;3.GPIOAFSEL initialize as 0, and we're not using their digital Alternate function.
	CLEARBITS GPIOEDEN, 2_11         ;4.Config AINx AS analog input-clear corresponding DEN bit in(GPIOEDEN) (PP682).
	SETBITS GPIOEAMSEL, 2_11         ;5. WRITE TO GPIOEAMSEL (687) ANALOG INPUTS TO BE ANALOG.
                                     ;6. SAMPLE SEQUENCER PRIORITY BEYOND SCOPE OF COURSE.

;CONFIGURE Sample Sequencer 0------------------------------------------------

	CLEARBITS ADCACTSS, 0x1          ;1. disable SAMPLE SEQUENCER-clear ASENn bit in ADCACTSS.
	CLEARBITS ADCEMUX, 0xF           ;2. SET SS0 TRIGGER IN ADCEMUX TO USE 'PROCESSOR' TRIGGERING.
                                     ;3. NOT using a PWM generator as the trigger source.
	WRITEBITS ADCSSMUX0, 0x00000032  ;SET BITS FOR EACH input source in the ADCSSMUXn register.
	WRITEBITS ADCSSCTL0, 0x00000060  ;5. SET ADCSSCTL0 SO THAT 2ND IN SEQUENCE ENDS SEQUENCE AND STARTS INTERRUPT.
                                     ;6. SKIP - NOT USING INTERRUPT6. If interrupts are to be used, set the corresponding MASK bit in the ADCIM register.
	WRITEBITS ADCPC, 1 ; set samples per second to 125,000. 

	SETBITS ADCACTSS, 0x1            ;7. Enable sample sequencer0 - setting the  ASEN0 bit in the ADCACTSS register.

			 
    POP { R4-R11, LR }
    BX LR; Return back to the calling subroutine.

;=======================LOGIC==========================;

__main


	; Activate PORTS (B, E) and corresponding pins 
	BL _led_pins_activation 

; Initialize our LEDs so we can turn them on/off at will.
   	BL _led_initialization

; Turns on two lights if setbits correctly implemented
	LDR R0, =GPIOBDATA_RW
	MOV R1, #LED_RIGHT
	ADD R1, #LED_DOWN
	BL _SETBITS
	
	NOP ; BREAKPOINT 1
	
	BL _CLEARBITS
	
	NOP ; BREAKPOINT 2

    ; Initialize our ADC Module so we can read from PE0 and PE1 
    BL _adc_initialization


	LDR R8, =THRESH_LOW
	LDR R9, =THRESH_HIGH
	
; 5. At this point we need to implement a loop which reads the data from each 
;    of the A/D data registers corresponding to the pins we have set up, and 
;    implement logic to decide which, if any, LEDs we should trigger in
;    response. This will occur within the update_loop label.

loop

; Clear interrupt flag so that we know we're reading a *new* adc conversion	
	SETBITS ADCISC, 0X01 ; STEP 5-1A
; Start processor trigger (tell sequencer 0 to start converting ADCs)
	SETBITS ADCPSSI, 1 ; STEP 5-1B
	

; Wait until reading is complete (use end flag) STEP 5-2
	LDR R0, =ADCRIS; _wait_adc EXPECTS TO HAVE THE ADC-Raw Interrupt Status address loaded into r0.
	BL _wait_adc	; and come back from there once you have ADC conversions for us.

; read axes 
	LDR R0, =ADCSSFIFO0
	BL _read_adc 
	MOV R5, R0  ;STEP 5-3 store the first read value-- x-value-- in R5.
	LDR R0, =ADCSSFIFO0
	BL _read_adc
	MOV R6, R0  ;STEP 5-4 store y-value
	
; turn off all LEDS (GPIOxDATA_RW - ports for LEDs)
leds_off
	CLEARBITS GPIOBDATA_RW, 0XFF ;STEP 5-5 TURN OFF ALL PB OUTPUTS.
; STUDENT CODE HERE 
	NOP	;****STEP 5A**** REMEMBER: WITHOUT CODE, THERE IS NO PLACE FOR A BREAKPOINT
	CMP R6, #THRESH_HIGH  	;****STEP 6A**** COMPARE R6 WITH HIGH THRESHOLD, BRANCH TO _TURN_ON_UP_LED IF HIGH,
	BLGT _TURN_ON_UP_LED	;****STEP 6C**** IF COMPARE ENDS WITH OTHER RESULTS, BRANCH TO TURN OFF THAT LED
	BLLT _TURN_OFF_UP_LED
			;****STEP 6D...**** NOW DO THE SAME FOR DOWN, LEFT, AND RIGHT.
	CMP R6, #THRESH_LOW
	BLLT _TURN_ON_DOWN_LED
	BLGT _TURN_OFF_DOWN_LED
	
	CMP R5, #THRESH_HIGH
	BLGT _TURN_ON_RIGHT_LED
	BLLT _TURN_OFF_RIGHT_LED
	
	CMP R5, #THRESH_LOW
	BLLT _TURN_ON_LEFT_LED
	BLGT _TURN_OFF_LEFT_LED

	B loop

_TURN_ON_UP_LED ; ****STEP 6B**** CREATE A SUBROUTINE HERE THAT TURNS ON LED AND RETURNS
	PUSH { R4-R11, LR }
	SETBITS GPIOBDATA_RW, LED_UP
	POP { R4-R11, LR }
	BX LR
	
_TURN_OFF_UP_LED
	PUSH { R4-R11, LR }
	CLEARBITS GPIOBDATA_RW, LED_UP
	POP { R4-R11, LR }
	BX LR
	
_TURN_ON_RIGHT_LED ;
	PUSH { R4-R11, LR }
	SETBITS GPIOBDATA_RW, LED_RIGHT
	POP { R4-R11, LR }
	BX LR
	
_TURN_OFF_RIGHT_LED
	PUSH { R4-R11, LR }
	CLEARBITS GPIOBDATA_RW, LED_RIGHT
	POP { R4-R11, LR }
	BX LR

_TURN_ON_DOWN_LED ;
	PUSH { R4-R11, LR }
	SETBITS GPIOBDATA_RW, LED_DOWN
	POP { R4-R11, LR }
	BX LR
	
_TURN_OFF_DOWN_LED
	PUSH { R4-R11, LR }
	CLEARBITS GPIOBDATA_RW, LED_DOWN
	POP { R4-R11, LR }
	BX LR
	
_TURN_ON_LEFT_LED ;
	PUSH { R4-R11, LR }
	SETBITS GPIOBDATA_RW, LED_LEFT
	POP { R4-R11, LR }
	BX LR
	
_TURN_OFF_LEFT_LED
	PUSH { R4-R11, LR }
	CLEARBITS GPIOBDATA_RW, LED_LEFT
	POP { R4-R11, LR }
	BX LR
	
; END STUDENT CODE
	
	END
		
