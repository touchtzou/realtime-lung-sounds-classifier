;*************************************************************************
; 	Module Name:k_nn.asm
;*************************************************************************
; 	 
;   Descirption: this subroutine implements the K-nearest neighbor
; 	         algorithm. As the name implies, it finds the nearest
;		 K distances between the vector to be classified and
;	         the training data. Then it determines the class labels
;	         of these K values.
;   Input/Output:
;	      Input:
;		 y:train_indx=the index of the training vector
;		 nt=the number of the training vectors
;		 k_value=the value of K used in K-nn algorithm
;		 n=number of segments to be classified in each sub-phase
;	      Output:
;		 y:kdist=array of the k-nearest distances
;		 y:kcl=array of labels of the k nearest neighbors
;		 y:dfar=the furthest distance in the k-nn pool
;		 y:kfar=index of the furthest distance in the pool
;		 y:dist=the calculated new distance
;
;   Register Usage:
;	 	 r1=pointer to kdist array
;		 r2=pointer for kcl array
;		 r5=temporary storage
;		 n0=counter for nt_loop and inital_dist loops
;		 n1=used for kdist array address generation
;	 	 n2=used for kcl array address generation
;		 n3=counter for k_loop
;		 n5=counter for kk_loop
;
;*************************************************************************


	org	y:

train_indx	ds	1	; the index of the current training vector

nt	equ	42		; Number of training data vectors
kdist	equ	*		; Distances array of size 'k_value'
	ds	k_value
kcl	equ	*		; Array of k_value class labels
	ds	k_value
kfar	ds	1
dfar	ds	1	; Distance of furthest neighbor currently
			; in the pool of k nearest neighbors

dist	ds	1	; Used to save the calculated distance


	org	p:
k_nn
	move	r1,x:(r6)+	; save these registers to the software
	move	r2,x:(r6)+	; stack pointed to by address register 'r6'
	move	r5,x:(r6)+	;
	move	n0,x:(r6)+	;
	move	n1,x:(r6)+	;	
	move	n2,x:(r6)+	;
	move	n3,x:(r6)+	;
	move	n5,x:(r6)+	;
	
	move	#kdist,r1
	move	#kcl,r2
	move	#k_value,n0
	move	#0,x0		; label of class-0
	move	#$7fffff,x1	; maximum expected distance

	do	n0,inital_dist	; initialize k nearest neighbor pool
	move	x0,y:(r2)+	; by first setting labels to default class-0 then
	move	x1,y:(r1)+	; all distances to a very large number (ideally infinity)
inital_dist

	move	#0,y1
	move	y1,y:train_indx

	move	#>nt,n0

;******************************************************************
; Go through all training vectors, computing their distances to the
; input vector and updating the k nearest neighbor pool
;******************************************************************
	do	n0,nt_loop	; repeat this loop 'nt' times
	nop
	nop	

	do	#n,subject_space  ; compare the input vector with 
				  ; each of the ten segments that
				  ; constitute the corresponding
				  ; respiratory sub-phase

;*******************************************************************
; calculate the distance between the vector to be classified and the
; training vector. The calculated distance is stored in y:dist
;*******************************************************************
	btst	#euclidean_flag,x:flags
	jcs	choose_euclid
	
	btst	#cityblock_flag,x:flags
	jcs	choose_city
	jmp	choose_itakura
	
choose_euclid
	jsr	euclidean_metric	; use Euclidian distance measure
	
	jmp	check_distance
choose_city	
	jsr	cityblock_metric	; use city-block  (Hamming) metric
	nop
	jmp	check_distance
choose_itakura
	jsr	itakura_metric		; use Itakura distance measure

check_distance

	move	y:next_database,a  ; update the address so that it points 
	move	#>(nk+1),x1	   ; to the next vector in the training
	add	x1,a		   ; data database
	move	a1,y:next_database ;

	move	#>k_value,n3
	move	#kdist,r1
;********************************************************************
; check if the calculated distance is nearer than any of current pool
;********************************************************************
	do	n3,k_loop	; repeat the k_loop according to the value
				; specified by 'k_value'
	move	y:dist,x0	; Get the distance from the input vector to the
				; training vector

	move	y:(r1)+,a	; if the calculated distance is greater than the
	sub	x0,a		; distances stored in the k-nn pool then return 
	jle	k_loop-1	; to the start of the loop
				
	move	y:kdist,x1 	; otherwise find furthest, so that it can be replaced

	move	x1,y:dfar	; y:dfar=kdist[current index]
	move	#0,x0		
	move	x0,y:kfar	; y:kfar=0 (start with class-0)

	move	#kdist,r1	; the start address of kdist array
	move	#kcl,r2		; the start address of the labels' array

	move	#>k_value,n5
	move	#>1,n1
	move	n1,r5

	do	n5,kk_loop	; Repeat the kk_loop as specified by 'k_value'
	move	y:dfar,a	; Calculate where to place the calculated distance
	move	y:(r1+n1),x0	; in the k-nn pool
	sub	x0,a		; if dfar<kdist[r1+n1] then the furthest element dfar is
				; kdist[r1+n1] and the new index 'kfar' is equal to n1
	jge	kk_loop-2	; otherwise, go to the next kdist element without any 
				; modifications
	move	x0,y:dfar
	move	n1,y:kfar	; k_far now contains the index of the kdist array
				; to which the calculated distance will be stored

	lua	(r5)+,r5
	move	r5,n1
kk_loop
	nop
	nop
	move	y:kfar,n1
	move	y:dist,x0	; replace an old distance with the calculated new
	move	x0,y:(r1+n1)	; distance
		
	jsr	get_label	; find the class index of the current training data
				; and store the result in x0

	move	n1,n2		
	move	x0,y:(r2+n2)	; Store the class index in the corresponding kcl array
				; element
	enddo			; If the calculated distance is greater than all the 
				; distances in the k-nn pool then all k-nn pool is set
				; to nearest
	nop
	nop
k_loop
	nop
	nop
subject_space

	nop
	nop

	move	y:next_subject,a	;
	move	#>((nk+1)*60),x1	;
	add	x1,a			;
	move	a1,y:next_database
	move	a1,y:next_subject

	move	y:train_indx,b0
	inc	b
	move	b0,y:train_indx
nt_loop
	nop	
	move	x:-(r6),n5	; restore the values of these registers from the 
	move	x:-(r6),n3	; software stack
	move	x:-(r6),n2	;
	move	x:-(r6),n1	;
	move	x:-(r6),n0	;
	move	x:-(r6),r5	;
	move	x:-(r6),r2	;
	move	x:-(r6),r1	;

	rts
		include	'get_label.asm'		
		include	'itakura_metric.asm'
		include	'euclidean_metric.asm'
		include	'cityblock_metric.asm'
