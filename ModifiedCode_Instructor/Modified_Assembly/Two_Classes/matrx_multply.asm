;*************************************************************************
; Module Name: matrx_multply.asm
;*************************************************************************
; Description: Multiplies the matrix whose address is stored in mat_a
; 	with the matrix whose address is in mat_b. The result is stored
;	in the array mat_c. The dimension of the input matrices is passed
;	to this subroutine through the variables row_a,column_a,row_b and 
;	column_b (implements C=AB)
;	Note: the input matrices A and B should be stored in Y memory
;
; Input/Output:
;	Input:
;		x:row_a=the number of rows in matrix A
;		x:column_a=number of columns of A
;		x:row_b=number of B rows
;		x:column_b=number of B columns
;		x:mat_a=starting address of matrix A
;		x:mat_b=starting address of matrix B
;	Output:
;		x:mat_c=an array contains the multiplication result
;
; Register Usage:
;	r0=pointer to elements of matrix A
;	r1=temporary pointer to A
;	r2=output matrix C pointer
;	r4=B matrix pointer
;	r5=temporary pointer to B
;	n0=used as address displacement for the next row of A
;	n1=loop counter (contains row number of A)
;	n2=loop counter (contians column number of B)
;	n3=loop counter of '_inner_sum'
;	n5=used for address calculation (contains column dimension of B)
;	
;************************************************************************

        opt     cex
        page    132,66,0,0

        org     x:
row_a      	ds	1
column_a   	ds	1
row_b      	ds	1
column_b   	ds	1
mat_a		ds	1  
mat_b		ds	1                      
mat_c  		ds      (nk+1)*(nk+1)	; a max. space of (nk+1)*(nk+1)
					; words is allocated for output
					; matrix C

        org     p:
matrx_multply
	move	r0,x:(r6)+	; push to stack
	move	r1,x:(r6)+	;
	move	r2,x:(r6)+	;	
	move	r4,x:(r6)+	;
	move	r5,x:(r6)+	;
	move	r7,x:(r6)+	;
	move	n0,x:(r6)+	;
	move	n1,x:(r6)+	;
	move	n2,x:(r6)+	;
	move	n3,x:(r6)+	;
	move	n5,x:(r6)+	;
	
	move    x:mat_a,r0       ;point to A matrix
        move    x:mat_b,r4       ;point to B matrix
        move    #mat_c,r2        ;output to C matrix
        move    x:row_b,n0       ;second dimension of A
        move    x:column_b,n5    ;second dimension of B

	move	x:row_a,n1
	move	x:column_b,n2
	move	n1,r7

_ew
	nop
	do      n2,_ez         	; number of final columns
        move    r0,r1           ; copy ptr
        move    r4,r5           ; copy second ptr
        clr     a
        move    y:(r1)+,x0
	move	y:(r5)+n5,y0	

	move	x:row_b,b0
	dec	b
	move	b0,n3

        do     	n3,_inner_sum   ; inner sum
        mac     x0,y0,a
	move	y:(r1)+,x0
	move	y:(r5)+n5,y0
_inner_sum	
	
        macr    x0,y0,a   (r4)+ ; move to next column in B
        move    a,x:(r2)+       ; save result
_ez
        move    (r0)+n0         ; move to next row in A
        move    x:mat_b,r4      ; point back to first column in B

	lua	(r7)-,r7
	move	r7,b
	cmp	#0,b
	jge	_ew		; repeat the_ew loop as specified
				; by the number of final rows

	move	x:-(r6),n5	; pop from stack
	move	x:-(r6),n3	;
	move	x:-(r6),n2	;
	move	x:-(r6),n1	;
	move	x:-(r6),n0	;
	move	x:-(r6),r7	; 
	move	x:-(r6),r5	;
	move	x:-(r6),r4	;
	move	x:-(r6),r2	;
	move	x:-(r6),r1	;
	move	x:-(r6),r0	;
	

	rts
