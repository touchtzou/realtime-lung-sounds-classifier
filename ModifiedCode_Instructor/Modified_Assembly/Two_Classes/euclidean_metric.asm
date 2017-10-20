;*******************************************************************************
; Module Name: euclidean_metric.asm
;*******************************************************************************
; Description: this subroutine uses the Euclidean distance measure to calculate
;	the distance between two vectors
; Input/Output:
;	Input:
;		y:next_lpc_lung=the address of the vector to be classified
;		y:next_database=the starting address of the training vectors
;	Output:
;		y:dist=the calculated distance in fractional format
;		y:difference=temporary storage place for the difference between
;			     two vector elements
;
; Registar Usage:
;		r0=pointer to the vector to be classified
;		r1=pointer to the training vector database
;		n0=loop counter
;
;
;*******************************************************************************
	org	y:
difference	ds		1	; temporary storage place for the 
					; difference between two vector elements
	
	org	p:

euclidean_metric
	move	r0,x:(r6)+	; push register values to software stack
	move	r1,x:(r6)+	;
	move	n0,x:(r6)+	;

	move	y:next_lpc_lung,r0	; r0 contains the address of the 
					; vector to be classified		

	move	y:next_database,r1  	; r1 contains the starting address
					; of the training data database
	clr	b
	move	#>(nk+1),n0

	do	n0,all_distances
	move	y:(r0)+,a
	move	y:(r1)+,x0
	sub	x0,a
	move	a,x1
	move	x1,y1
	mpy	x1,y1,a
	add	a,b
	
all_distances
	move	b,y0			
	jsr	square_root		; Find square root of the number in y0
	move	b,y:dist		; The calculated square root is in 'b'

	move	x:-(r6),n0	; pop from stack
	move	x:-(r6),r1	;
	move	x:-(r6),r0	;
	rts

	include	'square_root.asm'	; input --> y0, output --> b
