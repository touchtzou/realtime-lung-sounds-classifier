;*******************************************************************************
; Module Name: cityblock_metric.asm
;*******************************************************************************
; Description: this subroutine uses the city-block distance measure to calculate
;	the distance between two vectors
; Input/Output:
;	Input:
;		y:next_lpc_lung=the address of the vector to be classified
;		y:next_databae=the starting address of the training vectors
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
	
	org	p:

cityblock_metric
	move	r0,x:(r6)+	; push register values to software stack
	move	r1,x:(r6)+	;
	move	n0,x:(r6)+	;

	move	y:next_lpc_lung,r0	; r0 contains the address of the 
					; vector to be classified		

	move	y:next_database,r1  	; r1 contains the starting address
					; of the training data database

	clr	b
	move	#>(nk+1),n0

	do	n0,distances
	move	y:(r0)+,a
	move	y:(r1)+,x0
	sub	x0,a
	abs	a
	add	a,b
	
distances
	move	b,y:dist
	
	move	x:-(r6),n0	; pop from stack
	move	x:-(r6),r1	;
	move	x:-(r6),r0	;
	rts

