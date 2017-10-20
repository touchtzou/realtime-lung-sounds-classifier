;------------------------------------------------------------------------
; Module Name: autocorr.asm	
;------------------------------------------------------------------------
;
; Description:This function returns the autocorrelation sequence of
;	     a column vector of length N .
;	
;	
; Input/Output:
;	Input: 
;		r2 = Length of input vector A
;		r3 = Maximum Lag
;		
;		X:INA = data of vector A
;	Output:
;		X:INA+ LENGTH(A) = data of autocorrelation vector c		
;		
; Memory Usage:
;	x memory:
;		X:INA			-- data of input vector A
;		X:INA+ LENGTH(A)	-- data of output vector C		
; Register usage:
;	index of vector C -> r1
;	index of vector A -> r0
;	index of vector A -> r4
;	temporary storage of r7 -> n7
;	temporary address of vector A -> r7
;	loop control : r5, r6
;	assumes M{0...7} = $ffffff
;
;------------------------------------------------------------------------

	org	p:

autocorr
	MOVE	#INA,R0
	CLR	A	X:(R0)+,X0
	DO	R2,find_r0
	MAC	X0,X0,A		X:(R0)+,X0	
find_r0

;********************************************************************
; The autocorrelation coefficient at zero lag is calculated first.
; Since the max. value of autocorr. coeffs. will occur at lag zero,
; normalizing all the other coefficients according to this value will
; prevent overflows. When r(0) is normalized, it is actually split 
; into two parts: exponent and mantissa. The resulting exponent value
; is used only as the amount of shifts that is needed before moving
; them from accumulator to memory.
;********************************************************************

	move	#>24,r0
	rep	#24	; normalize r(0)
	norm	r0,a	;
	move	r0,b	; move exponent to b
	RND	A	

	move	#>24,x1
	sub	x1,b
	cmp	#0,b
	jge	large_corr
	abs	b
	move	b,y1	; y1 contains the amount of shift needed
			; to scale up the autocorr. coeffs.

	move	#0,x1	; x1=0 is used as a flag to show that no scale 
			; down is used here

	jmp	small_corr

large_corr
	abs	b
	move	b,x1	; x1 contains the amount of shift needed
			; to scale down the autocorr. coeffs.

	move	#0,y1	; y1=0 is used as a flag to show that no scale 
			; up is used here
small_corr

	MOVE	#INA,R0
	MOVE	#INA,R1
	MOVE	#INA,R4
	MOVE	R2,N1
	LUA	(R1)+N1,R1	;start address of output vector C
	MOVE	R2,A
	MOVE	R3,X0
	MOVE	R7,N3
		
	MOVE	#INA,N7
	SUB	X0,A
	MOVE	R3,R7		;start address of a[j+n-i+1]
	MOVE	A,R6		;initialize i
	MOVE	R3,R5

	LUA	(R7)+N7,R7	;start address of a[j+n-i+1]

;-----------------------------------------------------------
; The autocorrelation vector for all lags are calculated
; next. Then the proper scaling is applied to each one.
;-----------------------------------------------------------
	MOVE	#INA,R0
	MOVE	R2,R6		;initialize i
	MOVE	#INA,R7		;start address of a[j+n-i+1]
	MOVE	R2,A
	MOVE	R3,X0
	CMP	X0,A
	LUA	(R3)+,R5
	
	DO	R5,lag_values
	MOVE	R7,R4
	CLR	A	X:(R0)+,X0	
	MOVE	X:(R4)+,Y0
	DO	R6,current_lag
	MAC	X0,Y0,A		X:(R0)+,X0	
	MOVE	X:(R4)+,Y0
current_lag
	
	move	y1,b	; if y1=0 then this shows that the	
	cmp	#0,b	; calculated autocorr. values should be
			; scaled down by the amount stored in x1,
			; otherwise they should be scaled up by
			; the amount stored in y1

	jeq	scaled_down_corr
	asl	y1,a,a
	jmp	scaled_up_corr	

scaled_down_corr
	asr	x1,a,a		; Scale down each calculated autocorr.
				; coeff. by the amount stored in
				; x1. This normalizes each coeff.
				; according to r(0)
scaled_up_corr
	RND	A		
	MOVE	A,X:(R1)+	;store the calculated value c(i)
	LUA	(R7)+,R7
	LUA	(R6)-,R6
	MOVE	#INA,R0
lag_values
	nop
	rts
