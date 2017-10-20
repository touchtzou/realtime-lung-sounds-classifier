;**************************************************************************************
; Module Name: log10.asm
;**************************************************************************************
; Description:	This routine finds the base 10 logarithm of the unnormalised 24 bit
;		fraction in the accumulator..The scaled result is returned in the 
;		accumulator (the input must be a non-zero positive fraction)
;   
; Algorithm : 
;       Three steps are required.
;
;       1. Normalize the input so that 0.5 =< A < 1.0.
;       2. Calculate the log10(A).
;       3. Divide the result by 32.0
;	Bu using the following relationship 
;			log10(Z) = log2(Z)*log10(2)
;	and by using the following polynomial approximation:
;			log2(Z)	=  pi3*(Z**3) +	pi2*(Z**2) + pi1*Z + pi0
;						i = 1, 2, 3.   
;
;		       The range of the input number is divided into three different sub
;		       ranges and corresponding pij's (i=1,2,3; j=0,1,2,3) are used for
;		       each range. 
;		
;		       Range 1:
;		       1 > Z > 0.8
;		
;		               p13 =  0.6651550174712363
;		               p12 = -2.691225081621167
;		               p11 =  4.830861130814611
;		               p10 = -2.8047790282999791
;		
;		       Range 2:
;		       0.8 >= Z > 0.64
;		
;		               p23 =  1.299130893496323
;		               p22 = -4.205039190029353
;		               p21 =  6.038576413515295
;		               p20 = -3.126707123185897
;		
;		       Range 3:
;		       0.64 >= Z >= 0.5
;		
;		               p33 =  2.62317472043452
;		               p32 = -6.720343733123614
;		               p31 =  7.635399480799159
;		               p30 = -3.465490657054861
;
;		In the following pseudo	code cij = pij/8 (i=1,2,3)
;							 (j=0,1,2,3)
;			log2nrm(Z) = [log2(ZS)/8 + (-S)/8]/2
;
;		Find S such that ZS = (2**S)*Z	lies in	the range [0.5,1)
;		Find the range of ZS.
;
;		If 1 > ZS > 0.8
;		  Range	1:		
;		  Find Term1_1 = c13* ZS + c12
;		  Find Term1_2 = Term1_1*ZS + c11 
;		  Find log2(ZS)/8 = Term1_2 * ZS + c10 
;
;		If 0.8 >= ZS > 0.64
;		  Range	2:
;		  Find Term2_1 = c23 * ZS + c22
;		  Find Term2_2 = Term2_1 * ZS +	c21
;		  Find log2(ZS)/8 = Term2_3 * ZS + c20
;
;		If  0.64 >= ZS >= 0.5
;		  Range	3:
;		  Find Term3_1 = c33 * ZS + c32
;		  Find Term3_2 = Term3_1 * ZS +	c31
;		  Find log2(ZS)/8 = Term3_2 * ZS + c30
;
; Input/Output:
;	Input :	the input value in the accumulator 'a'
;		y:pcoef(n)= coefficients of polynomial (for n=1,2,3)
;		
;	Output:	the calculated logarithm in accumulator a
;
; Register Usage:
;	
;	r1=pointer to polynomial coefficients
;	r2=temporary storage
;	
;*************************************************************************************


	org	y:
pcoef1	dc	0.60385764135183	;coefficient c11
	dc	-0.35059737853750	;coefficient c10
	dc	-0.33640313520265	;coefficient c12
	dc	0.08314437718390	;coefficient c13
				  
pcoef2	dc	0.75482205168941	;coefficient c21
	dc	-0.39083839039824	;coefficient c20
	dc	-0.52562989875367	;coefficient c22
	dc	0.16239136168704	;coefficient c23
				 
pcoef3	dc	0.95442493509989	;coefficient c31
	dc	-0.43318633213186	;coefficient c30
	dc	-0.84004296664045	;coefficient c32
	dc	0.32789684005432	;coefficient c33

lncoef	equ	0.30102999566398	;log10(x) = log10(2)*log2(x)
					;lncoeff = log10(2)


	org	P:
log10
	move	r1,x:(r6)+		; push register values to stack
	move	r2,x:(r6)+		;

;	step 1 - normalize a to	get value between .5 and 1.0
	clr	b	
	clb	a,b		;register A contain the	input value
	normf	b1,a
	move	b1,r2		;save b1 in r2
	move	a,x0		;put normalized	number in x0
	move	#0.8,y0
	cmp	y0,a		;compare zs and	.8, if zs < .8 then go to _rang2
	blt	lb_rang2	;else continue with _rang1
lb_rang1
	move	#pcoef1,r1	;point to polynomial coefficients for log2
	jmp	lb_compute
lb_rang2	
	move	#0.64,y0
	cmp	y0,a		;compare zs and	.8, if zs < .64	then go	to _rang3
	blt	lb_rang3	;else continue with _rang1
	move	#pcoef2,r1	;point to polynomial coefficients for log2
	jmp	lb_compute
lb_rang3	
	move	#pcoef3,r1
;
;	Step 2 - Calculate LOG2	by polynomial approximation.
;
;	lognrm2(Z)	=  ci3*(Z**3) +	ci2*(Z**2) + ci1*Z + ci0
;					( i = 1,2,3)
;	where  0.5 <= x	< 1.0
;
;	r1 initially points to the coefficients	in y memory in the
;	order: ci1, ci0, ci2, ci3
;
lb_compute
	
	mpyr	x0,x0,b		y:(r1)+,y0		;zs^2 to b, ci1	to y0
	mpy	x0,y0,a		b,x1	y:(r1)+,y1	;zs*ci1->a, zs^2 to x1,	ci0 to y1
	mpyr	x0,x1,b		y:(r1)+,y0		;zs^3 to b, ci2	to y0
	mac	x1,y0,a		y:(r1)+,y0		;zs^2*ci2+a, ci3 to y0
	add	y1,a		b,x1			;ci0+a,	zs^3 to	x1
	macr	x1,y0,a					;zs^3*ci3+a	
;
;	Step 3 - Divide	result by 32
;
	asl	#4,a,a			; log2(zs)*8 and shift out sign	bit
	move	r2,b0			; normalize shift bit to b0
	dec	b
	
	move	b0,a2			;new sign = characteristic

	asr	#6,a,a			; log2(zs)/32
	
	move	#lncoef,x1		; move log10(2) coeff to x1
	move	a,y0			; move log2(zs)	to y0
	mpyr	x1,y0,a			; 'a' contians the result #lncoef*log2(zs)

	move	x:-(r6),r2		; pop from software stack
	move	x:-(r6),r1		;
	

	rts

