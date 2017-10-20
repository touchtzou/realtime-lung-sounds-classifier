;*******************************************************************************
; Module Name: find_distance.asm
;*******************************************************************************
; Description: This subroutine finds the distance between the lpc vector to be
;	classified and the training data. The distance metric used is the Itakura
;	distance measure.
; Input/Output:
;	Input:
;		nk=LPC model order
;		y:autocorr_matrx=the elements of the autocorrelation matrix
;		y:next_database=address of training vector
;		x:row_a=rows number of a
;		x:column_a=number of columns of matrix a
;		x:row_b=rows number of b
;		x:column_b=columns number of b
;		x:mat_a=starting address of matrix a elements
;		x:mat_b=starting address of b
;
;	Output:
;
;		y:dist=calculated distance between the input vector and training
;		       vector
;		x:mat_c=starting address of the calculated output matrix
;		
;
;
; Register Usage:
;	r0 & x0=temporary storage
;	r1=pointer to temp_vetor
;
;
;*******************************************************************************
	org	y:
temp_vector	ds	nk+2


	org	p:

itakura_metric
	move	r0,x:(r6)+	; push register values to software stack
	move	r1,x:(r6)+	;
	
	
	move	#>1,r0			; Define the dimensions (rows*columns)
	move	r0,x:row_a		; of the first matrix to be multiplied
	move	#>(nk+1),r0		; 'mat_a'
	move	r0,x:column_a
	move	y:next_database,r0	; r0 contains the starting address
	move	r0,x:mat_a		; of the training data database
	


	move	#>(nk+1),r0		; Define the dimensions of the second
	move	r0,x:row_b		; matrix to be multiplied (the autocorrelation
	move	#>(nk+1),r0		; matrix)
	move	r0,x:column_b
	move	#autocorr_matrx,r0
	move	r0,x:mat_b
	

	jsr	matrx_multply		; form the matrix (reference_LPC'*AUTOCORR_MATRIX)
					; where ' indicates matrix transpose operation


	move	#mat_c,r0		; the above calculated matrix is passed to 
	move	#temp_vector,r1		; temporary vector
	do	#(nk+1),load_a		;
	move	x:(r0)+,x0		;
	move	x0,y:(r1)+		;
load_a

	move	#temp_vector,r0		; the temporary vector is used again in the 
	move	r0,x:mat_a		; matrix multiplication subroutine to form
	move	#>nk+1,r0		; the following value:
	move	r0,x:row_b		; (reference_LPC'*AUTOCORR_MATRIX*reference_LPC)
	move	#>1,r0			;
	move	r0,x:column_b		;
	move	y:next_database,r0	;
	move	r0,x:mat_b		;
	jsr	matrx_multply		;	
	move	x:mat_c,a		;
	
	jsr	log10			
	move	a,x:dividend		; this calculated value is the logarithm of the
					; dividend needed in the calculation of the Itakura
					; distance (the logarithm function here produces
					; results scaled down by a factor of 32)

;---------------------------------------------------------------------------------
; NOTE: Instead of finding the Itakura distance as log10(dividend/divisor), it is
; calculated as 'log10(dividend)-log10(divisor)'. This method was considered
; because the ratio 'dividend/divisor' is greater than one and this will cause
; problems while using the fractional logarithm function. Another solution may be
; finding log10(divisor/dividend) and taking the absolute value of the resulting
; value, but the above mentioned method gave better results.
;---------------------------------------------------------------------------------
	move	x:divisor,x0
	sub	x0,a
	move	a,y:dist

	move	x:-(r6),r1	; pop from stack
	move	x:-(r6),r0	;

	rts
	include	'log10.asm'
