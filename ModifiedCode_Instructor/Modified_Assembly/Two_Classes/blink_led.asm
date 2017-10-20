;***********************************************************************************
; Module Name: blink_led.asm
;***********************************************************************************
;
; Description: this subroutine is used to blink one of the LEDs connected to
;	       a timer output with a predetermined frequency.
;
;
;***********************************************************************************


;***********************************************************************************
; The following variables are used by "blink_led" subroutine for the timer leds
;***********************************************************************************

M_TCSR         EQU	$FFFF8F
;----------------------------------------------------------------------------
; Address of Timer Control/Status Register (TSR0)
;----------------------------------------------------------------------------

TCSR		   EQU	$002800
;----------------------------------------------------------------------------
; The above value disables Timer 0 (used as GPIO), set direction to output, 
; and sends a 1 to turn on LED3
;----------------------------------------------------------------------------

TCSR_LED_ON    EQU     $002800
;----------------------------------------------------------------------------
; The above value disables Timer 0 (used as GPIO), Set direction to output, 
; and sends a 1 to turn on LED3
;----------------------------------------------------------------------------

TCSR_LED_OFF   EQU     $000800
;----------------------------------------------------------------------------
; The above value disables Timer 0 (used as GPIO), Set direction to output, 
; and sends a 0 to turn off LED3
;----------------------------------------------------------------------------

blink_led
	movep		#$000fff,x:M_TPLR		; Timer clock source=internal 
							; Prescale value =fffh = 4096d
							; CLK = 98.3MHz
							; 1/(98.3MHz/2)=20.35nS
							; Prescaler counts
							; = 4096*20.35nS = 83.34us
							; prescaler toggle time=83.34us*

	movep		#$000000,x:M_TLR1		; Timer reload value
	movep		#$000384,x:M_TCPR1		; Timer compare value(900h=384d)
							; 75ms=83.34us*900=output toggle
		
	movep		#$208a20,x:M_TCSR1		; clock source is prescaler output
							; TIO pin is output, reload on 
							; count in TCR
							; Enable Timer Mode 2
	bset		#21,x:M_TCSR1			; Clear timeout bit before returning
							; Note: bit is cleared by writing a 1
	movep		#$008a21,x:M_TCSR1

	rts
