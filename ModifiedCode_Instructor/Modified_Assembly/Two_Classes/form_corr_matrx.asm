;******************************************************************************
; Module Name:form_corr_matrx.asm
;******************************************************************************
;
; Description: formulates the autocorrelation matrix using the autocorrelation
;	 coefficients at lags 0,1,...,nk.
;
; Input/Output:
;	Input:		
;		nk=max lag (model order)
;		y:next_corr_lung=the starting address of the autocorrelation
;				 sequence
;	Output:
;		y:autocorr_matrx=array used to store the autocorrelation matrix
;
; Register Usage:
;	r0=pointer to autocorr. sequence
;	r1=pointer to the calculated autocorr. matrix
;	r2=temporary address storage
;
;
; NOTE: each element of the autocorrelation matrix is scaled down (divided by 2)
;	by shifting right one bit
;
;*******************************************************************************
	org	y:

autocorr_matrx	equ	*	; array used to store the autocorrelation
	ds	(nk+1)*(nk+1)	; matrix


		org	p:
form_corr_matrx

	move	r0,x:(r6)+		; push to stack
	move	r1,x:(r6)+		;
	move	r2,x:(r6)+		;

	move 	#autocorr_matrx,r1
	move	y:next_corr_lung,r0	; r0 contains the starting address of
					; the estimated autocorrelation sequence
	move	r0,r2
	move	r0,a
	add	#>nk,a
	move	a1,y1

;-------------------------------------------------------------------------------
	do	#nk+1,next_row		; form a matrix of nk+1 rows

	move	r0,a			; if the autocorr. sequence
	move	y:next_corr_lung,y1	; pointer is at the beginning
	cmp	y1,a			; of the array then storage begins
	jne	descend_corr		; with r(0),r(1),...(increasing lag)
	move	#0,r3			; Otherwise the storage is in descending
	jmp	ascend_corr		; order ...,r(1),r(0) (decreasing lag)
descend_corr
	move	#>1,r3
ascend_corr
	do	#nk+1,form_row		; a loop used for each element of a row

	move	r3,a	
	cmp	#>1,a
	jeq	descending
	
	move	y:(r0)+,a		; scale down each matrix element then
	asr	a			; form the matrix row with autocorrelation
	move	a,y:(r1)+		; sequence of increasing lag
	jmp	form_row-1		

descending
	move	y:(r0)-,a		; scale down each matrix element then
	asr	a			; form the matrix row with autocorrelation
	move	a,y:(r1)+		; sequence of increasing lag
				
	
	move	r0,a			; check if we reached the first autocorr.
	cmp	y1,a			; coefficient, if so then the next coefficient
	jne	descend_again		; storage will be in ascending order (increasing
	move	#0,r3			; lag)
	jmp	form_row-1
descend_again
	move	#>1,r3
	nop
form_row
	lua	(r2)+,r2		; point to the next autocorrelation coefficient
	move	r2,r0			; in the array
next_row
	move	x:-(r6),r2		; pop from stack
	move	x:-(r6),r1		;
	move	x:-(r6),r0		;

	rts
