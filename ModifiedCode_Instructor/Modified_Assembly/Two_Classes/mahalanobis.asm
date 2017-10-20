;*****************************************************************************
;   Module Name: mahalanobis.asm
;*****************************************************************************
; 	 
;   Descirption: this subroutine finds the distance between the vector to 
;		 be classified and the training data according to the 
;		 Mahalanobis distance measure. Then it classifies the input
;		 vector (segment) to the class that results in the minimum
;		 distance.
;
;   Input/Output:
;	      Input:
;		ncl=number of classes
;		nk=modeling order
;		x:next_covar=The starting address of inverse of the
;			     covariance matrix
;		x:next_feature=The starting address of the estimated
;			       mean feature vectors
;		x:old_distance=The current nearest neighbor's distance
;		x:class_indx=The class label of the nearest neighbor
;
;	      Output:
;		y:dist=the calculated distance according to Mahalanobis metric
;		y:segment_vote=the calculated class of the current segment
;		y:vect_difrence=an array used to store the difference between
;				two vectors
;		y:temp_vector=temporary storage array of length (nk+2)
;
;
;   Register Usage:
;		r0,r1,r2=used as pointers and/or temporary storage areas
;		n0=loop counter
;
;*****************************************************************************


	org	x:

old_distance	ds	1	; The current nearest neighbor's distance
class_indx	ds	1	; The class label of the nearest neighbor
	
next_covar	ds	1	; The starting address of inverse of the
				; covariance matrix

next_feature	ds	1	; The starting address of the estimated
				; mean feature vectors
	org	y:
vect_difrence	equ	*	; an array used to store the difference between
	ds	nk+2		; the feature vector to be classified and the mean
				; feature vector for each class

	org	p:

mahalanobis

	move	r0,x:(r6)+	; save to stack
	move	r1,x:(r6)+	;
	move	r2,x:(r6)+	;
	move	n0,x:(r6)+	;


	move	#0,x0			; Label of class-0
	move	#$7fffff,x1		; Maximum expected distance

	move	x0,x:class_indx		; Initialize class index  and 		  
	move	x0,y:segment_vote	; segment vote to default class-0 then
	move	x1,x:old_distance	; set the distance to  a very large number
					; (ideally infinity)


;**********************************************************************
; Go through all the inverse of the covariance matrices and their mean 
; feature vectors computing their distances to the input vector. Then
; determine the class label of the nearest neighbor
;*********************************************************************
	move	#ncl,n0
	do	n0,all_classes	; repeat this loop as specified by 
				; the number of classes (ncl)

	move	y:next_lpc_lung,r0	; ignore the first element
	move	r0,a0			; in the LPC array
	inc	a			;
	move	a0,r0			;

	move	x:next_feature,r1
	move	#vect_difrence,r2


	do	#nk+1,find_difference	; find the difference between the 			
	move	y:(r0)+,a		; feature vector to be classified 
	move	y:(r1)+,x0		; and the mean feature vector for 
	sub	x0,a			; each class and store the result
	move	a,y:(r2)+		; in the array 'vect_difrence'
find_difference

	move	#vect_difrence,r0	; r0 contains the address of the vector	
	move	r0,x:mat_a		; which contains the difference between
	move	#>1,r0			; the vector to be classified and the
	move	r0,x:row_a		; mean feature vector (the first vector
	move	#>nk+1,r0		; in the matrix multiplication subroutine)
	move	r0,x:column_a		; Then define its dimensions (rows*columns)
	
	move	x:next_covar,r0		; define the starting address of 
	move	r0,x:mat_b		; the second vector to be multiplied
	move	#>nk+1,r0		; ( the inverse of covariance matrix)
	move	r0,x:row_b		; then pass its  dimensions
	move	#>nk+1,r0		;
	move	r0,x:column_b		;
	


	jsr	matrx_multply	 	; difference_vector'*(inverse_of_covariance_matrix)

	move	#mat_c,r0		; the above calculated matrix is passed to 
	move	#temp_vector,r1		; a temporary vector
	do	#nk+1,load_vector_a	;
	move	x:(r0)+,x0		;
	move	x0,y:(r1)+		;
load_vector_a


	move	#temp_vector,r0		; The result of the above multiplication process
	move	r0,x:mat_a		; will be multiplied again with the vector 	
	move	#>nk+1,r0		; difference_vector, thus forming the following value
	move	r0,x:row_b		; (difference_vector'*(inverse_of_covariance_matrix)*
	move	#>1,r0			; difference_vector)
	move	r0,x:column_b		;
	move	#vect_difrence,r0	;
	move	r0,x:mat_b		;
	jsr	matrx_multply		;	

	move	x:mat_c,a		; the resulting value is the distance calculated
	move	a,y:dist		; using Mahalanobis distance measure
	

;*****************************************************************
; check if the calculated distance is nearer than the previous one
;*****************************************************************

	move	y:dist,x0	; Get the calculated distance from the input
				; vector to the training data

	move	x:old_distance,a ; if the calculated distance is greater than the
	sub	x0,a		 ; previously stored one then return to the start
	jle	increment_indx	 ; of the loop

	move	x0,x:old_distance ; Replace the old distance with the calculated new
	move	x:class_indx,r0	  ; one. Then update the segment vote according to
	move	r0,y:segment_vote ; the value in 'class_indx'

increment_indx
	move	x:class_indx,b0		; increment the class index so as to be used
	inc	b			; in the next segment voting iteration
	move	b0,x:class_indx
		
	move	x:next_covar,a		; update the address so as to point to the 
	move	#>6*(nk+1)*(nk+1),x1	; address of the next inverse covariance matrix
	add	x1,a			; so as to use it in the calculation of the 
	move	a1,x:next_covar		; distance between the input vector and the next
					; class


	move	x:next_feature,a	; point to the address of the next mean feature
	move	#>6*(nk+1),x1		; vector to be used in the calculation of the 
	add	x1,a			; new distance between the input vector to be 
	move	a1,x:next_feature	; classified and the next class

all_classes

	move	x:-(r6),n0		; pop from stack
	move	x:-(r6),r2		;
	move	x:-(r6),r1		;
	move	x:-(r6),r0		;


	rts
