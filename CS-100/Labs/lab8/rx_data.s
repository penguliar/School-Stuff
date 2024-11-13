	AREA DATA, CODE, READONLY 

RCGCGPIO EQU 0X400FE608 ;Address of GPIO Module, it ACTIVATES PORTS...
							; ...bit 0 = port A, bit 1 = port B, ... and bit 5 = port F

; Serial communication is attached to lines PA0(receive) and PA1(transmit) 
GPIOADATA_RW EQU 0X400043FC ; Address of Port A (DATA)of our microcontroller (buttons)
GPIOADIR 	 EQU 0x40004400 ; Address of Port A (DIRECTION SETTING)of our microcontroller
GPIOADEN	 EQU 0X4000451C	; Address of Port A (DIGITAL SETTING) of our microcontroller

GPIOAAFSEL	 EQU 0X40004420 ; ***2A2- Address of Port A (alternate function select) of our microcontroller port a
GPIOAPCTL	 EQU 0X4000452C ; ***2A3- what the actual alternate function is for port a
	
GPIOBDATA_RW EQU 0X400053FC ; Address of Port B (DATA)of our microcontroller (LEDs)
GPIOBDIR 	 EQU 0x40005400 ; Address of Port B (DIRECTION SETTING)of our microcontroller
GPIOBDEN 	 EQU 0X4000551C ; Address of Port B (DIGITAL SETTING) of our microcontroller
;PWM Settings for Port B 
GPIOBAFSEL 	 EQU 0X40005420 ; Address of Port B (Alternate function SETTING) of our microcontroller
GPIOBPCTL 	 EQU 0X4000552C ; Address to configure which alternate function to use 
	
;PORT F - TIVABOARD USES PORT F, PINS PF1,PF2, AND PF3 FOR THE ONBOARD RGB LED
GPIOFDATA_RW EQU 0X400253FC ; ADDRESS OF PORT F PINS - DATA REGISTER
GPIOFDIR	 EQU 0X40025400 ; ADDRESS OF PORT F - DIRECTION
GPIOFDEN	 EQU 0X4002551C ; ADDRESS OF PORT F PINS - DIGITAL ENABLE
	
	
;UART ACCESS
RCGCUART	EQU 0X400FE618; ***2A1- ENABLE UART MODULE USING THIS REGISTER (344)
	
;UART general data
UART0		EQU 0x4000C000 ; Base address of all UART0 functions
UART0DR		EQU UART0 	   ;***2B address of the UART0 data register
UART0FR		EQU UART0+0x18 ;***2B UART0 flag register 
UART0IBRD	EQU UART0+0x24 ;***2B UART0 integer baud-rate divider register
UART0FBRD	EQU UART0+0x28 ;***2B UART0 fractional baud-rate divider register
UART0LCRH	EQU UART0+0x2C ;***2B UART0 Line Control register
UART0CTL	EQU UART0+0x30 ;***2B UART0 control register
UART0CC		EQU UART0+0xFC8 ;***2B UART0 Clock Configuration register


;ADC Settings for Port E 
GPIOEAMSEL 	 EQU 0X40024528 ; Address of Port E (ANALOG SETTING) of our microcontroller

;ADC General Settings
RCGCADC 	 EQU 0x400FE638 ; Enable ADC Module PROVIDES A CLOCK  BIT0 = MODULE 0 BIT1=MODULE 1
ADCPC 		 EQU 0X40038FC4 ; Select ADC Speed 1-125KSPS, 3-250KSPS, 5-500KSPS, 7 - 1MSPS
ADCACTSS 	 EQU 0X40038000 ; Address to enable and disable the ADC Sequencer (Seq 0 = Bit 0) ;;(BIT 0-3 SEQ 0 -3) BIT 16 - (0 IDLE) (1 BUSY) 
ADCEMUX 	 EQU 0X40038014 ; Select which event triggers the sample sequencer (Seq 0 bits(0- 3) 0XF = ALWAYS)
ADCSSMUX0 	 EQU 0X40038040 ; Select which ADC channels the sequencer 0 will read (AIN3 = PE0, AIN2 = PE1)
ADCSSCTL0 	 EQU 0X40038044	; Address to configure the sample control bits (interruption and end of sequencer) 
ADCRIS 		 EQU 0X40038004	
ADCSSFIFO0 	 EQU 0X40038048 ; DATA (BITS 0-11)
ADCISC 		 EQU 0X4003800C


;constants 
COUNT1 			EQU 0x00D00000


; macros
	MACRO
	TRANSMIT8BITS $BITS_TO_TRANSMIT
	MOV R0,#$BITS_TO_TRANSMIT
	BL _TRANSMIT
	MEND
	
	MACRO 
	WRITEBITS $addr, $data
	LDR R0, =$addr
	MOV R1, #$data
	STR R1, [R0]
	MEND

	MACRO
	SETBITS $ADDRESS, $BITS
	LDR R1,=$BITS
	LDR R0,=$ADDRESS
	BL _SETBITS
	MEND

	MACRO
	CLEARBITS $ADDRESS, $BITS
	LDR R1,=$BITS
	LDR R0,=$ADDRESS
	BL _CLEARBITS
	MEND

	MACRO 
	DLAY $DELAYLOOPCOUNT
	LDR R0,=$DELAYLOOPCOUNT
	BL _DELAY
	MEND



	END
		