;------------------------------------------------------------------
; Module Name: durbin.asm
;------------------------------------------------------------------
; Description: Implements the Durbin algorithm to find a solution
;	for PARCOR (LPC) Coefficients. The modeling order is 
;	defined by the value of nk.
;
;
; Input/Output:
;	Input:
;	   X:r  = autocorrelation coefficient sequence
;	   nk = model order
;	Output:
;	   Y:acoeffs = LPC coefficients of order nk
;	   X:k = reflection coefficients
;	   Y:anew = intermediate lpc coefficients
;
;
;
; Memory Usage:
;	X memory:
;	   X:r = autocorrelation coefficients
;	   X:k = reflection coefficients
;	Y memory:
;	   Y:acoeffs = The final calculated lpc coefficients
;	   Y:anew =  intermediate results of lpc coefficients
;
; Register Usage:
;       r0 - r[i]               r4 - acoeffs[i]
;       r1 - k[i-1]             r5 - acoeffs[j-1]
;       r2 - r[i-j+1]           r6 - acoeffs[i-j+1]
;       r3 - anew[j-1]          r7 - loop counter
;
; 
;----------------------------------------------------------------

        opt     cex
        page    132,66,3,3
;

  	org     x:	

r       ds      nk+1		;autocorrelation coefficients  
k       ds      nk              ;reflection coefficients

        org     y:              ;temporary values in Y: memory

scale_amount	equ	3
acoeffs dc      ($7fffff)/@CVI(@POW(2.0,scale_amount))  ;a[0]=1/(2^scale_amount)
        ds      nk              ;LPC filter coefficients
anew    dc      ($7fffff)/@CVI(@POW(2.0,scale_amount))  ;anew[0]=1/(2^scale_amount)
        ds      nk              ;updated LPC filter coefficients
alpha   ds      1               ;Durbin alpha
error   ds      1               ;Durbin error
 		org     p:

;
;       Initialization
;
durbin

	move	#INA,r0
	move	#length_A,n0
	lua	(r0)+n0,r0
	move	#r,r1  			;load autocorrelation
	do	#nk+1,autocor_move	;get nk+1 autocorrelation values
	move	x:(r0)+,a		;get next autocorrelation value
	move	a,x:(r1)+		;and save it in the r array
autocor_move

        move    #r,r0                   ;r(0) points to r[0]
        move    #k,r1                   ;r(1) points to k[0]
;
;       Begin Durbin Algorithm
;
        move    x:(r0)+,x0              ;get r[0]
        move    x:(r0)+,a               ;get r[1], r(0) points to r[i]
        abs     a          a,b          ;get abs(r[1]), copy r[1] to b
        eor     x0,b  #acoeffs+1,r4     ;N = sign bit, r(4) points to a[1]
        and     #$fe,ccr                ;make quotient positive
        rep     #24                     ;set up for 24-bit quotient
        div     x0,a                    ;get abs(r[1])/r[0]
        jmi     neg_reflect1            ;check sign bit N
        neg     a                       ;negate quotient if needed
neg_reflect1
	move    a0,a                    ;move -r[1]/r[0] to A
	
        clr     b   a,x:(r1)+  a,y0     ;k[1] = -r[1]/r[0], copy k[1] to y0
        move    #$800000,b1             ;b = 1.0, r(1) points to k[i-1]
        macr    -y0,y0,b  #2,r7         ;b=1.0-(k[1]*k[1]),loop counter=2
        move    b,x1  a,y:(r4)+         ;x1 = 1.0-(k[1] * k[1]), a[1] = k[1]
        mpyr    x1,x0,a   #2,n7         ;a1 = r[0] * (1.0 - (k[1] * k[1]))
        move    a,y1                    ;model_error= r[0] * (1.0 - k[1] * k[1]))
        move    #-2,n5                  ;initialize n(5) 


;**********************************************************************
; Now lets find the coefficients for the second iteration, then scale
; these coefficients by a factor specified by the immediate value of 
; scale_amount..This will result in the final coefficients of the wanted
; order to be scaled down by this amount, too.
;**********************************************************************

  	move    r0,r2                   ;r(2) points to r[i]
        move    #acoeffs,r5             ;r(5) points to a[0]
        move    (r0)+                   ;r(0) points to next r[i]
	
	move	y:(r5)+,a		; this value will be multiplied by
	asl	#scale_amount,a,a	; the autocorrelation coefficient 
	move	a,y0			; r[2] to calculate the second ref.
	clr	a	x:(r2)-,x0	; coeff. k[2], so no scaling is applied 
					; at this step

		
;------------------------------------------------------------------------
; The sum of the numerator of reflect. coeff. k[2] is calculated below
;------------------------------------------------------------------------
 do      r7,reflect2                   ;do this loop 2 times
 mac     x0,y0,a x:(r2)-,x0 y:(r5)+,y0 ;reflect_numer+= a[j-1] * r[i-j+1]	
	
reflect2
;------------------------------------------------------------------------

	abs     a          a,b    ;get abs(reflect_numer)
				  ;copy reflect_numer to b
	
        eor     y1,b       #2,n6  ;N = sign bit, y1=model_error
        and     #$fe,ccr          ;make quotient positive
        rep     #24               ;set up for 24-bit quotient
        div     y1,a              ;get abs(reflect_numer)/model_error
        jmi     neg_reflect2      ;check sign bit N
        neg     a                 ;negate quotient if needed
neg_reflect2
	move    a0,a       ;move k[2] = -(reflect_numer/model_error)
			   ;to a
        clr b	
	move	a,x:(r1)+  ;put k[i-1] in x0, a[i] = k[i-1]
	move	a,x0	   ;

	asr	#scale_amount,a,a	;a[2] is equal to the scaled
	move	a,y:(r4)+		;ref. coeff. k[2]
	move	y:(r7)-,a
        move    #$800000,b1             ;b = 1.0
        macr    -x0,x0,b    r4,r6       ;b = 1.0 - (k[2] * k[2])
        move    b,x1                    ;r(6) points to a[i+1]
        mpyr    x1,y1,b   (r6)-n6       ;b = model_error* (1.0-(k[2]*k[2]))

;----------------------------------------------------------------------
;  Find the modeling error of the current model so as to be used in the
;  next iteration according to the formula:
;           model_error=model_error*(1-k[i-1]*k[i-1]) 
;----------------------------------------------------------------------
        move    b,y1                    ;save model_error(2) in y1

        move    #acoeffs+1,r5           ;r(5) points to a[1]
        move    #anew+1,r3              ;r(3) points to anew[1]
        move    y:(r6)-,y0              ;y0 = a[i-j+1], x0 = k[i-1]
        move    y:(r5)+,a               ;a = a[1]


    
        macr    x0,y0,a  y:(r6)-,y0     ;get anew[j-1], y0 = next a[i-j+1]
	asr	#scale_amount,a,a	;anew[j-1]=a[j-1]+k[i-1]*a[i-j+1]
	move	a,y:(r3)+		;scale down a[1] and store it
	move	y:(r5)+,a		;

	move    x:(r3)-,x0 y:(r5)+n5,y0	;decrement r(3) and r(5)
        move    y:(r3)-,a               ;get anew[1]
        move    a,y:(r5)-               ;a[1] = anew[1]
	move    (r7)+n7                 ;update loop counter for next loops


;-----------------------------------------------------------------------
; The LPC coefficients at the end of this second iteration are scaled
; down by an amount specified by scale_amount..For the next iterations,
; this will result in the final desired coefficients to be scaled down
; by the same amount
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
; Now the Durbin recursion is executed staring from the iteration number
; 3 until the final desired order nk  
;-----------------------------------------------------------------------

        do      #nk-2,L6                    ;do outer do loop (nk-1) times
        move    r0,r2                       ;r(2) points to r[i]
        move    #acoeffs,r5                 ;r(5) points to a[0]
        move    (r0)+                       ;r(0) points to next r[i]
        clr     a  x:(r2)-,x0	y:(r5)+,y0  ;reflect_numer= 0
					    ;preload 1st operand set
	
;
;       inner do loop #1  (note: r7 = i)
;
        do      r7,L2                         ;do inner do loop #1 (i) times
        mac     x0,y0,a x:(r2)-,x0 y:(r5)+,y0 ;reflect_numer += a[j-1] * r[i-j+1]
;
;       back to outer do loop  (note: error = a)
;
	
	
L2      abs     a          a,b   ;get abs(reflect_numer) and
				 ;copy reflect_numer to b
	
        eor     y1,b       #2,n6 ;N = sign bit, y1 = model_error
        and     #$fe,ccr         ;make quotient positive
        rep     #24              ;set up for 24-bit quotient
        div     y1,a             ;get abs(reflect_numer)/model_error
        jmi     L3               ;check sign bit N
        neg     a                ;negate quotient if needed
L3      move    a0,a             ;move k[i-1] = -(reflect_numer/model_error)
				 ;to a


	move	a,y:(r4)+		; Store the scaled LPC coeff.
	asl	#scale_amount,a,a	; Scale up the corresponding
					; ref. coeff. then store it
	clr	b	
	move	a,x:(r1)+
	move	a,x0
	move	y:(r7)-,a


        move    #$800000,b1          ;b = 1.0
        macr    -x0,x0,b    r4,r6    ;b = 1.0 - (k[i-1] * k[i-1])
        move    b,x1                 ;r(6) points to a[i+1]
        mpyr    x1,y1,b   (r6)-n6    ;b = model_error * (1.0-(k[i-1]*k[I-1]))
        move    b,y1                 ;save model_error=model_error*(1-k[i-1]*k[i-1])
        move    #acoeffs+1,r5        ;r(5) points to a[j-1]
        move    #anew+1,r3           ;r(3) points to anew[j-1]
        move    y:(r6)-,y0           ;y0 = a[i-j+1], x0 = k[i-1]
        move    y:(r5)+,a            ;a = a[j-1]
;
;       inner do loop #2  (note: r7 = (i-1))
;
        do      r7,L4                   ;do inner do loop #2 (i-1) times
        macr    x0,y0,a  y:(r6)-,y0     ;get anew[j-1], y0 = next a[i-j+1]
        move    a,y:(r3)+               ;anew[j-1]=a[j-1]+k[i-1]*a[i-j+1]
        move    y:(r5)+,a               ;a = a[j-1]
;
;       end of inner do loop #2
;
;       inner do loop #3  (note: r7 = (i-1))
;
L4      move    x:(r3)-,x0 y:(r5)+n5,y0 ;dummy reads to dec r(3) and r(5)
        do      r7,L5                   ;do inner do loop #3 (i-1) times
        move    y:(r3)-,a               ;get anew[j-1]
        move    a,y:(r5)-               ;a[j-1] = anew[j-1]
;
;       end of inner do loop #3
;
;       end of outer do loop
;
L5      move    (r7)+n7                 ;update loop counter
	nop
L6      
        nop
;----------------------------------------------------------------------------
; The final calculated modeling error depends on the value of the initial
; error value r[0]. So, dividing this error value by r[0] will result in
; the assumption that the initial error value is taken as one. This step is
; needed to yield similar results with the ones that are produced by MATLAB	
;----------------------------------------------------------------------------
	move    #r,r0                   ;r(0) points to r[0]
	move    x:(r0),x0               ;get r[0]
        move    y1,a	                ;get final calculated modeling error
	abs     a          a,b          ;get abs(model error), copy it to b
        eor     x0,b       		;N = sign bit
        and     #$fe,ccr                ;make quotient positive
        rep     #24                     ;set up for 24-bit quotient
        div     x0,a                    ;get abs(model error)/r[0]
        jpl     pos_error            	;check sign bit N
        neg     a                       ;negate quotient if needed
pos_error

	move    a0,a            ;move the scaled modeling error to A
	move	a,x:model_error ;Save this modeling order. Here the autocorr.
				;coeff. at lag zero was taken as 1. This 
				;assumption was made here to yield similar
				;results with the ones calculated with MATLAB's
				;aryule() function 
	nop
	rts
