;********************************************************************************
; Module Name: fraction_division.asm
;********************************************************************************
; Description: This is a routine for a 4 quadrant divide (i.e., a signed divisor
;	 and a signed dividend) which generates a 24-bit signed quotient and a 
;	 48-bit signed remainder. The quotient is stored in the lower 24 bits of 
;	 accumulator A,A0, and the remainder in the upper 24 bits, A1. The true
; 	 (restored) remainder is stored in B1. The original dividend must occupy
;	 the low order 48 bits of the destination accumulator, A, and must be a 
;	 POSITIVE number.
; Input/Output:
;	Input:
;		x:dividend=contains the fractional dividend
;		x:divisor=contains the fractional divisor
;
;	Output:
;		x1=the quotient
;		b1=remainder
;
; Note: The divisor (x0) must be larger than the dividend (A) so that a fractional 
;	quotient is generated.
;
;*********************************************************************************

	org	p:
fraction_division:
	move x:dividend,a 	; move the dividend into A
	move x:divisor,x0 	; move the divisor into x0

	abs a a,b 		;make dividend positive, copy A1 to B1
	eor x0,b b,x:$0 	;save rem. sign in x:$0, quo, sign in N
	and #$fe,ccr 		;clear carry bit C (quotient sign bit)
	rep #$18 		;form a 24-bit quotient

	div x0,a 		;form quotient in A0, remainder in A1
	tfr a,b 		;save remainder and quotient in B1,B0
	jpl savequo 		;go to SAVEQUO if quotient is positive
	neg b 			;complement quotient if N bit is set

savequo tfr x0,b b0,x1 		;save quo. in X1, get signed divisor
	abs b 			;get absolute value of signed divisor
	add a,b 		;restore remainder in B1

	jclr #23,x:$0,finish	;go to finish if remainder is positive
	move #$0,b0 		;prevent unwanted carry
	neg b 			;complement remainder
finish 				;end of routine
	
	rts
