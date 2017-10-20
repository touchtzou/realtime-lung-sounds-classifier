;*******************************************************************************
; Module Name: integer_division.asm
;*******************************************************************************
; Description: This is a routine for performing signed integer division. The 
;	result is stored in a0.
; Input/Output:
;	Input:
;		x:dividend=contains the integer dividend
;		x:divisor=contains the integer divisor
;
;	Output:
;		a0=the quotient		
;
;
;*******************************************************************************

integer_division
	move x:dividend,a 	;sign extend a2
	move a2,a1 ;and A1
	move x:dividend,a0 	;move the dividend into A
	asl a x:divisor,x0 	;prepare for divide, and
				;move divisor into x0 (24 bit)
	
	abs a a,b 		;make dividend positive, save in B
	and #$fe,ccr 		;clear the carry flag
	rep #$18 		;form a 24-bit quotient

	div x0,a 		;form quotient in a0, remainder a1
	eor x0,b 		;save quotient sign in N

	jpl done 		;go to done if quotient is positive
	neg a 			;complement quotient if N bit is set

	nop 			;finished, the quotient is in a0	
	
done
	rts
