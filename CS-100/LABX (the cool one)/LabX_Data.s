	AREA DATA, CODE, READONLY 

RCGCGPIO EQU 0X400FE608 ;Address of GPIO Module, it ACTIVATES PORTS...
							; ...bit 0 = port A, bit 1 = port B, ... and bit 5 = port F

;Speaker must be connected to PB7 (PB7 = PWM Module 0: Generator 0: GEN B ), also called M0PWM1 (GEN A and GEN B share same freq and timer)

GPIOBDATA_RW 	EQU 0X400053FC ; Address of Port B (DATA)of our microcontroller (LEDs)
GPIOBDIR 	 	EQU 0x40005400 ; Address of Port B (DIRECTION SETTING)of our microcontroller
GPIOBDEN 	 	EQU 0X4000551C ; Address of Port B (DIGITAL SETTING) of our microcontroller

;PWM Settings for Port B 
GPIOBAFSEL 	 	EQU 0X40005420 ; Address of Port B (Alternate function SETTING) of our microcontroller
GPIOBPCTL 	 	EQU 0X4000552C ; Address to configure which alternate function to use 
	
;PWM General Settings
RCGCPWM 		EQU 0X400FE640 ; ENABLE PWM MODULE PROVIDE A CLOCK  BIT O MODULE 0 BIT 1 MODULE 1
SYSCTL_RCC 		EQU 0X400FE060 ; Microcontroller Clock Control Configuration 
PWM0CTL 		EQU 0X40028040 ;Disable/Enable PWM Generator
PWMENABLE 		EQU 0X40028008 ;Disable/Enable PWM Outputs
PWM0CMPB 		EQU 0X4002805C ;Value at which Output will change (Duty Cycle) 
PWM0GENB  		EQU 0X40028064 ;Control bits for PWM0, Configuration 
PWM0LOAD 		EQU 0X40028050 ;Period, cycles needed to count

;constants 
COUNT1 			EQU 0x00D00000
MIDDLE_C_DIV	EQU 0x1754 ; 261.626HZ
MIDDLE_D_DIV	EQU 0x14C9 ; 293.665HZ
MIDDLE_E_DIV	EQU 0x1284 ; 329.628HZ
MIDDLE_F_DIV	EQU 0x117A ; 349.228HZ
MIDDLE_G_DIV	EQU 0xF92 ; 391.995HZ
MIDDLE_A_DIV	EQU 0xDDF ; 440.000HZ
MIDDLE_B_DIV	EQU 0xC5C ; 493.883HZ
	
MAX_CMP			EQU 0X700
	
; macros
	MACRO
	SETBITS $addr, $data
	LDR R0, =$addr
	LDR R1, =$data
	BL _setbits
	MEND

	MACRO
	CLEARBITS $addr, $data
	LDR R0, =$addr
	LDR R1, =$data
	BL _clearbits
	MEND
	
	MACRO 
	DLAY $delayloopcount
	LDR R0,=$delayloopcount
	BL _delay
	MEND
	
	MACRO 
	writebits $addr, $data
	LDR R0, =$addr
	MOV R1, #$data
	STR R1, [R0]
	MEND

	END