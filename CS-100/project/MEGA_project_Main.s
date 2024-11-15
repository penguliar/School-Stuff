; CS 100 Lab 9
; Due Date:
; Student Name:	
; Section: 

; Title: "Lab9_Main"
; � 2021 DigiPen, All Rights Reserved.
	
	GET MEGA_project_Data.s             		; Get/include the data file
	GLOBAL __main               		; Global main function
	AREA MEGA_project_Main, CODE, READONLY		; Area of code that is read only
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
	CLEARBITS GPIOEDEN, 0x3         ;4.Config AINx AS analog input-clear corresponding DEN bit in(GPIOEDEN) (PP682).
	SETBITS GPIOEAMSEL, 0x3         ;5. WRITE TO GPIOEAMSEL (687) ANALOG INPUTS TO BE ANALOG.
                                     ;6. SAMPLE SEQUENCER PRIORITY BEYOND SCOPE OF COURSE.

;CONFIGURE Sample Sequencer 0------------------------------------------------

	CLEARBITS ADCACTSS, 0x1          ;1. disable SAMPLE SEQUENCER-clear ASENn bit in ADCACTSS.
	CLEARBITS ADCEMUX, 0xF           ;2. SET SS0 TRIGGER IN ADCEMUX TO USE 'PROCESSOR' TRIGGERING.
                                     ;3. NOT using a PWM generator as the trigger source.
	WRITEBITS ADCSSMUX0, 0x00000032  ;SET BITS FOR EACH input source in the ADCSSMUXn register.
	WRITEBITS ADCSSCTL0, 0x00000060  ;5. SET ADCSSCTL0 SO THAT 2ND IN SEQUENCE ENDS SEQUENCE AND STARTS INTERRUPT.
                                     ;6. SKIP - NOT USING INTERRUPT6. If interrupts are to be used, set the corresponding MASK bit in the ADCIM register.
						
	WRITEBITS ADCPC, 1 ; set samples per second to 125,000. 
	SETBITS ADCACTSS, 1 ; Enable sample sequencer 0
	
;SERIALIZATION STUFF	
	
	SETBITS GPIOADEN, 0X3				; Enable PA0 and PA1 as digital ports (not analog) - already done, but demonstrating how
	SETBITS RCGCUART, 0X1				; 3A- enable the UART module 0 (UART0) using RCGCUART (pp 344)		
	SETBITS RCGCGPIO, 0X0				; 3B- enable clock to GPIO module through RCGCGPIO (pp340/1351)
	SETBITS GPIOAAFSEL, 0X3				; 3C- Set GPIO Alternate function select GPIOAFSEL (671/1344) for both PA0 AND PA1
										; No need to configure GPIO drive control or slew rate (Defaults to 2-Ma drive, which is fine)
										; No need to configure PMCn fields in GPIOPCTL (Defualts to PA0/PA1, which is fine)
; EXAMPLE SPECIFIC TO 9600 BAUD/8BIT/1 STOP/NO PARITY/FIFO OFF/NO INTERRUPTS
	CLEARBITS UART0CTL, 0X1				; 5A- DISABLE UART WHILE OPERATING-- CLEAR UARTEN BIT (O) IN UARTCTL	
										; NOTE** PLL IS SET TO 3, SO WE'RE WORKING WITH 48MHz.  *
										; SET BAUD-RATE-DIVISOR FOR BRD=48,000,000/(CLKDiv-16 or 8)(9600)=III.FFFFF  
	WRITEBITS UART0IBRD, 312			; 5B- (Set UART0IBRD=III)
	WRITEBITS UART0FBRD, 32				; 5C- Set UART0FBRD = INT(0.FFFFF*64+0.5) - FROM 0 TO 64 for fraction
	WRITEBITS UART0LCRH, 0x60			; 5D- Select serial com. parameters in UARTLCRH (8 BITS, the rest should be default)
	WRITEBITS UART0CC, 0x0				; 5E- Configure UART Clock source in UART0CC (DEFAULT=0=SYSTEM CLOCK+DIVISOR)
	WRITEBITS UART0CTL, 2_1100000001		; 5F- Enable UART0 for receive, Enable UART0 for Transmit, Enable UART0 total

			 
    POP { R4-R11, LR }
    BX LR; Return back to the calling subroutine.

;-------------------------------------------
; Subtroutine: _SEND
; checks for the output fifo to be clear, then sends lowest 8 bits of R0

_TRANSMIT
  PUSH { R4-R11, LR } 			; stack preserved registers and link register
_WAIT_FOR_CLEAR_OUTPUT_FIFO
	LDR R1, =UART0FR			; 6A1- Load the address of the UART0 Flag register
	LDR R2, [R1]				; 6A2- Get the contents of the UART0 Flag register into a register we're not using
	TST R2, #1<<5				; 6B- Check the Transmit FIFO0 Full bit (TXFF) on that register with a TST (single bit ANDS)
	BNE _WAIT_FOR_CLEAR_OUTPUT_FIFO				; 6B1- If the Transmit FIFO0 IS full, go back to _WAIT_FOR_CLEAR_OUTPUT_FIFO
	AND R0, #0XFF				; 6C- Mask out all but the lowest 8 bits for sending from R0
	LDR R6, =UART0DR			; 6D1- Place the data in R0 into the UART0Data Register (UART0DR)
	STR R0, [R6]				; 6D2- (two lines)
  POP { R4-R11, LR } 			; Pop back the preserved registers and link register
  BX LR 				; Return back to the calling subroutine.
  
_RECEIVE
  PUSH { R4-R11, LR }
_WAIT_FOR_RECEIVE_OUTPUT_FIFO
	LDR R1, =UART0FR			; Load the address of the UART0 Flag register
	LDR R2, [R1]				; Get the contents of the UART0 Flag register into a register we're not using
	TST R2, #1<<4				; Check the Transmit FIFOO Empty bit (RXFE) on that register with a TST (single bit ANDS)
	BNE _WAIT_FOR_RECEIVE_OUTPUT_FIFO
	LDR R0, =UART0DR			; Place the data in R0 into the UART0Data Register (UART0DR)
	LDR R0, [R0]
	AND R0, #0XFF				; Mask out all but the lowest 8 bits for sending from R0
  POP { R4-R11, LR }			; Pop back the preserved registers and link register
  BX LR					; Return back to the calling subroutine.
  
  
;-------------------------------------------
_QUICKSEND PUSH { R4-R11, LR} ; For debug purposes
	TRANSMIT8BITS 'U'
	TRANSMIT8BITS 'p'
	TRANSMIT8BITS 13
	TRANSMIT8BITS 12
  POP { R4-R11, LR}
  BX LR
  
_TRANSCEND ; Bit mask and translate 12 bits into ASCII, then send it through _TRANSLATE
	PUSH { R4-R11, LR }
		ADD R0, #0x30
		CMP R0, #0x39
		ADDGT R0, #7
		BL _TRANSMIT
	POP { R4-R11, LR }
	BX LR
		
;=======================LOGIC==========================;

__main
	; Activate PORTS (B, E) and corresponding pins 
	BL _led_pins_activation 

; Initialize our LEDs so we can turn them on/off at will.
   	BL _led_initialization

; Turns on two lights if setbits correctly implemented
	; LDR R0, =GPIOBDATA_RW
	; MOV R1, #LED_RIGHT
	; ADD R1, #LED_DOWN
	; BL _SETBITS
	
	; NOP ; BREAKPOINT 1
	
	; BL _CLEARBITS
	
	; NOP ; BREAKPOINT 2

    ; Initialize our ADC Module so we can read from PE0 and PE1 
    BL _adc_initialization
	
; 5. At this point we need to implement a loop which reads the data from each 
;    of the A/D data registers corresponding to the pins we have set up, and 
;    implement logic to decide which, if any, LEDs we should trigger in
;    response. This will occur within the update_loop label.

	LDR R8, =THRESH_LOW
	LDR R9, =THRESH_HIGH

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
	
; Reading the 12 bits out of R5 and R6
	AND R0, R5, 0xF00
	LSR R0, #5
	BL _TRANSCEND
	AND R0, R5, #0xF0
	LSR R0, #4
	BL _TRANSCEND
	AND R0, R5, 0xF
	BL _TRANSCEND
	AND R0, R6, 0xF00
	LSR R0, #5
	BL _TRANSCEND
	AND R0, R6, #0xF0
	LSR R0, #4
	BL _TRANSCEND
	AND R0, R6, 0xF
	BL _TRANSCEND
	TRANSMIT8BITS 13
	
	
	
; turn off all LEDS (GPIOxDATA_RW - ports for LEDs)
; leds_off
	; CLEARBITS GPIOBDATA_RW, 0XFF ;STEP 5-5 TURN OFF ALL PB OUTPUTS.
; STUDENT CODE HERE 
	; NOP	;****STEP 5A**** REMEMBER: WITHOUT CODE, THERE IS NO PLACE FOR A BREAKPOINT
	; CMP R6, #THRESH_HIGH  	;****STEP 6A**** COMPARE R6 WITH HIGH THRESHOLD, BRANCH TO _TURN_ON_UP_LED IF HIGH,
	; BLGT _TURN_ON_UP_LED	;****STEP 6C**** IF COMPARE ENDS WITH OTHER RESULTS, BRANCH TO TURN OFF THAT LED
	; BLLT _TURN_OFF_UP_LED
			;****STEP 6D...**** NOW DO THE SAME FOR DOWN, LEFT, AND RIGHT.
	; CMP R6, #THRESH_LOW
	; BLLT _TURN_ON_DOWN_LED
	; BLGT _TURN_OFF_DOWN_LED
	
	; CMP R5, #THRESH_HIGH
	; BLGT _TURN_ON_RIGHT_LED
	; BLLT _TURN_OFF_RIGHT_LED
	
	; CMP R5, #THRESH_LOW
	; BLLT _TURN_ON_LEFT_LED
	; BLGT _TURN_OFF_LEFT_LED
	
	
	;****STEP 5A**** REMEMBER: WITHOUT CODE, THERE IS NO PLACE FOR A BREAKPOINT
	; CMP R6, #THRESH_HIGH  	;****STEP 6A**** COMPARE R6 WITH HIGH THRESHOLD, BRANCH TO _TURN_ON_UP_LED IF HIGH,
	; BLGT _QUICKSEND	;****STEP 6C**** IF COMPARE ENDS WITH OTHER RESULTS, BRANCH TO TURN OFF THAT LED

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
		
