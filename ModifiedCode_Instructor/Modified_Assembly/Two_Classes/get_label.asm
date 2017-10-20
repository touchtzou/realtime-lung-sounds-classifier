;************************************************************************
; Module Name: get_label.asm
;************************************************************************
; Description: This routine calculates the class label  of the training
;	       vector and returns the result in register x0
; Input/Output:
;	Input:
;		y:train_indx = training vector's index
;		y:class_end = array of training vector sizes	
;		y:class(n)_size =sizes of training vectors belonging to
;			         different classes (n=0,1,2,...,ncl-1) 
;	Output:
;		x0 = the calculated class label's index
; Register Usage:
;	r0 = pointer to class_end array 
;	r1 = used as loop counter
;*************************************************************************


	org	y:

class_end	equ	*	; Array contains the number of training 				
class0_size	dc	21	; vectors in each class starting from the 
class1_size	dc	21	; first class until class number 'ncl-1'

		org	p:
get_label
	
	move	r0,x:(r6)+	; push to software stack
	move	r1,x:(r6)+	;

	move	#class_end,r0
	move	y:train_indx,x0
	move	#0,r1
	clr	a

wrong_label		
	move	y:(r0)+,x1  ; if the training vector's index falls within the
	add	x1,a	    ; first class region (0<training index<class0_size)
	cmp	x0,a	    ; then the label is class-0..Otherwise check if the
	lua	(r1)+,r1    ; training vector index belongs to class-1 that is check
	jle	wrong_label ; if class0_size<training index<class0_size+class1_size,
			    ; otherwise.......

	lua	(r1)-,r1
	move	r1,x0	

	move	x:-(r6),r1	; pop from stack
	move	x:-(r6),r0	;
	rts
	
