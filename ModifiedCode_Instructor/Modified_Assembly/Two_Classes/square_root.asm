;****************************************************************************
; Module name: square_root.asm
;****************************************************************************
;
; Description: Full 23 bit precision square root routine using a successive 
;	approximation technique. 
;
; Input/Output;
;	Input: y0
;	Output: b
;
; Memory & Register usage:
;	b  = output root
;	a  = temporary storage
;	x0 = guess
;	x1 = bit being tested
;	y0 = input number
;	
;****************************************************************************
	
	org     p:

square_root					
	clr	b	#<$40,x0	; init root and	guess
	move	x0,x1			; init bit to test
	do	#23,all_bits
					; START	OF LOOP
	mpy	-x0,x0,a		; square and negate the	guess
	add	y0,a			; compare
	tge	x0,b			; update root if input >= guess
	tfr	x1,a			; get bit to test
	asr	a			; shift	to next	bit to test
	nop
	add	b,a	a,x1		; form new guess
	nop
	move	a,x0			; save new guess
all_bits				; END OF LOOP
	
	rts
