; CS 100 Lab 8
; Due Date:	10/30/24
; Student Name: Aeden Brookshire
; Section: B
; © 2022 DigiPen, All Rights Reserved.

	GET rx_data.s

	GLOBAL __main
    AREA Main, CODE, READONLY
    ALIGN 2
    ENTRY

;===============Bit Methods, nothing new to see here, move along=======================;
_SETBITS ; Turn on bits at address R0 specified by 1's in R1 
	PUSH {R4-R11, LR}
	LDR R4, [R0]
	ORR R4, R1
	STR R4, [R0]
	POP {R4-R11, LR}
	BX LR

_CLEARBITS ; Turn off bits at address R0 specified by 1's in R1
	PUSH {R4-R11, LR}
	LDR R4, [R0]
	MVN R3, R1
	AND R4, R3
	STR R4, [R0]
	POP {R4-R11, LR}
	BX LR

_DELAY ; Loop R0 times
	PUSH {R4-R11, LR}
	MOV R10, R0
LOOPDELAY
	SUBS R10, R10, #1
	CMP R10, #0 
	BNE LOOPDELAY
	POP {R4-R11, LR}
	BX LR



;==================SETUP GPIOs, nothing new to see here, move along==========================;
; Subroutine: output_pins_config Sets up output pins -Inputs:None, Outputs:None
output_input_pins_config 
	
  PUSH { R4-R11, LR } 				; push registers and link register to save them for what follows-
	SETBITS RCGCGPIO, 0X33    			; Read in the current GPIO Module configuration and Enable Ports A, B, E AND F
    SETBITS GPIOADEN, 0XF3				; Configure used pins of Port A as digital (PA0,1,4-7)
	SETBITS GPIOBDEN, 0xC0 				; PB7, pb6 (2_11000000)	;Configure used pins of Port B as digital
	SETBITS GPIOFDEN, 0x0E 				; Configure pins 1PF1, PF2 and PF3 for use (TIVA LAUNCHPAD RGB LED)
	SETBITS GPIOADIR, 0XF0 				; PA7, PA6, PA5, PA4 (2_11110000) as output
	SETBITS GPIOBDIR, 0xC0 				; Enable PB7, pb6 (2_11000000) for output
	SETBITS GPIOFDIR, 0x0E 				; Configure PF1, PF2 and PF3 for OUTPUT (TIVA LAUNCHPAD RGB LED)
	CLEARBITS GPIOFDATA_RW, 0x0E 		; Initialize pins PF1, PF2 and PF3 as off 	
    
  POP { R4-R11, LR } 				; Pop back contents from the stack onto the registers they came from
  BX LR							; Return back to the calling subroutine.


;----------THIS IS WHERE WE NEED WORK DONE-----------------------  
; Subroutine: adc_initialization
; Description: Initializes our ADC Module and Sequencer so they are set up for analog input. 


SERIAL_INITIALIZATION
  PUSH { R4-R11, LR } 				; push preseverd registers and link register onto the stack to save them
	SETBITS GPIOADEN, 0X3				; Enable PA0 and PA1 as digital ports (not analog) - already done, but demonstrating how
	SETBITS RCGCUART, 0X1				; 3A- enable the UART module 0 (UART0) using RCGCUART (pp 344)		
	SETBITS RCGCGPIO, 0X0				; 3B- enable clock to GPIO module through RCGCGPIO (pp340/1351)
	SETBITS GPIOAAFSEL, 0X3				; 3C- Set GPIO Alternate function select GPIOAFSEL (671/1344) for both PA0 AND PA1
										; No need to configure GPIO drive control or slew rate (Defaults to 2-Ma drive, which is fine)
										; No need to configure PMCn fields in GPIOPCTL (Defualts to PA0/PA1, which is fine)
SERIAL_CONFIGURATION
; EXAMPLE SPECIFIC TO 9600 BAUD/8BIT/1 STOP/NO PARITY/FIFO OFF/NO INTERRUPTS
	CLEARBITS UART0CTL, 0X1				; 5A- DISABLE UART WHILE OPERATING-- CLEAR UARTEN BIT (O) IN UARTCTL	
										; NOTE** PLL IS SET TO 3, SO WE'RE WORKING WITH 48MHz.  *
										; SET BAUD-RATE-DIVISOR FOR BRD=48,000,000/(CLKDiv-16 or 8)(9600)=III.FFFFF  
	WRITEBITS UART0IBRD, 312			; 5B- (Set UART0IBRD=III)
	WRITEBITS UART0FBRD, 32				; 5C- Set UART0FBRD = INT(0.FFFFF*64+0.5) - FROM 0 TO 64 for fraction
	WRITEBITS UART0LCRH, 0x60			; 5D- Select serial com. parameters in UARTLCRH (8 BITS, the rest should be default)
	WRITEBITS UART0CC, 0x0				; 5E- Configure UART Clock source in UART0CC (DEFAULT=0=SYSTEM CLOCK+DIVISOR)
	WRITEBITS UART0CTL, 2_1100000001		; 5F- Enable UART0 for receive, Enable UART0 for Transmit, Enable UART0 total
	POP { R4-R11, LR } 		; Pop back the preserved registers and link register to what they were when we started SERIAL_INITIALIZATION
  BX LR 				; Return back to the calling subroutine.

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
_QUICKSEND PUSH { R4-R11, LR}
	TRANSMIT8BITS 'Y'
	TRANSMIT8BITS 'o'
	TRANSMIT8BITS 'u'
	TRANSMIT8BITS ' '
	TRANSMIT8BITS 'p'
	TRANSMIT8BITS 'r'
	TRANSMIT8BITS 'e'
	TRANSMIT8BITS 's'
	TRANSMIT8BITS 's'
	TRANSMIT8BITS 'e'
	TRANSMIT8BITS 'd'
	TRANSMIT8BITS ' '
	TRANSMIT8BITS 't'
	TRANSMIT8BITS 'h'
	TRANSMIT8BITS 'e'
	TRANSMIT8BITS ' '
	TRANSMIT8BITS 'l'
	TRANSMIT8BITS 'e'
	TRANSMIT8BITS 't'
	TRANSMIT8BITS 't'
	TRANSMIT8BITS 'e'
	TRANSMIT8BITS 'r'
	TRANSMIT8BITS ' '
	TRANSMIT8BITS '''
	TRANSMIT8BITS 'A'
	TRANSMIT8BITS '''
	TRANSMIT8BITS 13
	TRANSMIT8BITS 12
  POP { R4-R11, LR}
  BX LR


;==================LOGIC==========================;

__main

_INITIALIZATION_ROUTINES
	BL output_input_pins_config 
	BL SERIAL_INITIALIZATION
	
_RUNLOOP ; MADE UP OF READ-SEND-RECEIVE SECTIONS
	BL _RECEIVE
	CMP R0, #'A'
	CMP R0, #'a'
	BLEQ _QUICKSEND

_LOOP_END
	DLAY 1000000
	B _RUNLOOP
	
	END
	
	

		
		
		