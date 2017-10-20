;**********************************************************************************
; Module Name: find_phase_vote.asm
;**********************************************************************************
; Description:this subroutine goes through all the 10 segments that constitute each
;	      of the respiratory sub-phases, classifies each segment and returns
;	      the found class votes of the sub-phase to the array phase_votes
;
; Input/Output:
;	Input:
;		k_value=the value of 'K' in k-nn algorithm
;		n=the number of segments to be classified in each sub-phase		
;		y:next_corr_lung=address of estimated autocorrelation coefficients				
;		y:next_lpc_lung= Address of the vector to be classified
;		y:next_database=Address of the training vector in the database
;
;
;	Output:
; 		y:phase_votes=used to store the found phase vote
;		y:segment_vote= used to store the winner class label of the 
;				cuurent segment
;		y:vote=this array contains the votes for each class
;		y:autocorr_matrx=starting address of the autocorrelation matrix
;
; Register Usage:
;	r0 & n0=used to select the appropriate element in the array 'kcl'
;	r1=loop counter
;	r2 & n2=used to select the appropriate element in the 'vote' array
;	r3 & n3=address generation of the proper element in the phase_votes array
;	n4=loop counter used to go through all the segments of a phase
;***********************************************************************************


 	org	y:

k_value		equ	5	; the value of K in the k-nn algorithm

segment_vote	ds	1	; Used to store the winner class label
n	equ	10		; n is the number of vectors to be classified
				; in each sub-phase
vote	equ	*		; this array contains the votes for each class
	ds	ncl

segment_no	ds	1	; a variable used to store the current segment number

next_lpc_lung	ds	1	; Address of the vector to be classified
next_database	ds	1	; Address of the training vector in the database
next_corr_lung	ds	1	; Address of the autocorrelation sequence

next_data_seg	ds	1
next_subject	ds	1

	org	p:
find_phase_vote

	move	r0,x:(r6)+		; push to software stack
	move	r1,x:(r6)+		;
	move	r2,x:(r6)+		;
	move	r3,x:(r6)+		;
	move	n0,x:(r6)+		;
	move	n2,x:(r6)+		;
	move	n3,x:(r6)+		;
	move	n4,x:(r6)+		;

;----------------------------------------
	move	#n,n4			; repeat the classification process n times
	do	n4,all_phase		; (the number of the segments to be classified)


	btst	#mahalanob_flag,x:flags
	jcc	choose_knn

	move	y:segment_no,a		; The variable segment_no is used to determine
	cmp	#9,a			; the sub-phase that the segment belongs to. The 
	jle	early_insp_cov		; address of the inverse covariance matrix 
	cmp	#19,a			; and the mean feature vector to be used in the 
	jle	mid_insp_cov		; Mahalanobis subroutine is determined accordingly
	cmp	#29,a			;
	jle	late_insp_cov		;
	cmp	#39,a			;
	jle	early_exp_cov		;
	cmp	#49,a			;
	jle	mid_exp_cov		;

	move	#>5*(nk+1)*(nk+1),x0	; this segment belongs to the late exp sub-phase 
	move	#>5*(nk+1),y0		;
	jmp	call_mahalanob

early_insp_cov		
	move	#0,x0			; Use the inverse covariance matrix and the mean
	move	#0,y0			; feature vector that belong to the early insp. 
	jmp	call_mahalanob		; sub-phase	

mid_insp_cov
	move	#>(nk+1)*(nk+1),x0	; Use the inverse covariance matrix and the mean
	move	#>(nk+1),y0		; feature vector that belong to the mid insp. 
	jmp	call_mahalanob		; sub-phase

late_insp_cov
	move	#>2*(nk+1)*(nk+1),x0	; Use the inverse covariance matrix and the mean
	move	#>2*(nk+1),y0		; feature vector that belong to the late insp. 
	jmp	call_mahalanob		; sub-phase


early_exp_cov
	move	#>3*(nk+1)*(nk+1),x0	; Use the inverse covariance matrix and the mean
	move	#>3*(nk+1),y0		; feature vector that belong to the early exp. 
	jmp	call_mahalanob		; sub-phase

mid_exp_cov
	move	#>4*(nk+1)*(nk+1),x0	; Use the inverse covariance matrix and the mean
	move	#>4*(nk+1),y0		; feature vector that belong to mid exp. sub-phase 
	
call_mahalanob
	move	#>covar_matrx,a		; 
	move	#>mean_features,b	;
	add	x0,a
	move	a,x:next_covar
	add	y0,b
	move	b,x:next_feature

	jsr	mahalanobis

	move	y:next_lpc_lung,a	; update the address for the next vector to be 
	move	#>(nk+2),x1		; classified
	add	x1,a			;
	move	a1,y:next_lpc_lung	;
	jmp	skip_knn

;----------------------------------------

choose_knn
	move	y:next_database,r0
	move	r0,y:next_data_seg
	move	r0,y:next_subject	

	move 	#vote,r1		; initialize votes for classes
	move	#0,x0			; with zero before classification
	move	#ncl,n0			; process
	rep	n0			; 
	  move	  x0,y:(r1)+		;


	btst	#itakura_flag,x:flags	; the result of the following portion of code is 
	jcc	not_itakura		; used only if the itakura_flag is set..If it is
					; not chosen then skip it!

	jsr	form_corr_matrx		; the formed autocorrelation matrix is
					; needed  for the Itakura distance metric
	
	move	y:next_lpc_lung,r0	; r0 contains the address of the	
	move	r0,x:mat_a		; vector to be classified (the first
	move	#>1,r0			; matrix in the multiplication process).
	move	r0,x:row_a		; Define its dimensions (rows*columns)
	move	#>(nk+1),r0
	move	r0,x:column_a

	move	#autocorr_matrx,r0	; define the starting address of 
	move	r0,x:mat_b		; the second vector to be multiplied
	move	#>(nk+1),r0		; then pass its  dimensions
	move	r0,x:row_b		;
	move	#>(nk+1),r0		;
	move	r0,x:column_b		;
	
	jsr	matrx_multply		; calculate (estimated_LPC'*AUTOCORR_MATRIX)

	move	#mat_c,r0		; pass the matrix multiplication result to 
	move	#temp_vector,r1		; a temporary vector
	do	#(nk+1),load_matrx	;
	move	x:(r0)+,x0		;
	move	x0,y:(r1)+		;
load_matrx

	move	#temp_vector,r0		; The result of the above multiplication process
	move	r0,x:mat_a		; will be multiplied again with the vector 				
	move	#>(nk+1),r0		; estimated_lpc, thus forming the following value
	move	r0,x:row_b		; (estimated_LPC'*AUTOCORR_MATRIX*estimated_LPC)
	move	#>1,r0			;
	move	r0,x:column_b		;
	move	y:next_lpc_lung,r0	;
	move	r0,x:mat_b		;
	jsr	matrx_multply		;

	move	x:mat_c,a		; the resulting value is used as the divisor
	jsr	log10			; in the Itakura distance measure (the logarithm
	move	a,x:divisor		; function here produces results scaled down by
					; a factor of 32)

not_itakura		
	nop
	
	jsr	k_nn			; find the nearest K values to the vector to be
					; classified

	
	move	y:next_lpc_lung,a	; update the address for the next vector to be 
	move	#>(nk+2),x1		; classified which will be used by 'k_nn' in
	add	x1,a			; next iteration
	move	a1,y:next_lpc_lung	;


	move	y:next_corr_lung,a	; update the address for the autocorrelation of 
	move	#>(nk+1),x1		; the next vector to be classified using 'k_nn'
	add	x1,a			; in next iteration
	move	a1,y:next_corr_lung	;


	
;***********************************************
; calculate the vote for each class in K-nn pool  
;***********************************************
	move	#0,r1
voting:
	move	r1,n0			                                      
	move	#kcl,r0		; Load the address of the array containing the class
				; labels

	move	y:(r0+n0),n2	; n2 contains the element kcl[r1]
	move	#vote,r2	; Load the 'vote' array's address

	move	y:(r2+n2),a	; 'a' contains the element vote[kcl[r1]]

	add	#>1,a		; Increment the vote of the appropriate class
				; that is increment vote[kcl[k]]
	move	a,y:(r2+n2)	; Save the updated vote value

	lua	(r1)+,r1	; Repeat the above block of code 'k_value' times
	move	r1,a		; that is calculate the votes for all the k-nn pool
	cmp	#>k_value,a	;
	jlt	voting		;

	move	#vote,r1
	move	r1,y:votes_array
	jsr	find_max_indx
	move 	y:voting_winner,r1
	move 	r1,y:segment_vote
	
skip_knn
	
	move	y:segment_no,a0		; go to the next segment
	inc	a			;
	move	a0,y:segment_no		;

	move	y:next_data_seg,r1
	move	r1,y:next_database

	move	#phase_votes,r3	
	move	y:segment_vote,n3
	move	y:(r3+n3),a0
	inc	a
	move	a0,y:(r3+n3)

	nop
	nop	
all_phase
	nop
	nop
	
	move	y:next_data_seg,a	;
	move	#>((nk+1)*10),x1	;
	add	x1,a			;
	move	a,y:next_database

	move	a,y:next_data_seg

	move	n4,x:-(r6)		; pop from software stack
	move	n3,x:-(r6)		;
	move	n2,x:-(r6)		;
	move	n0,x:-(r6)		;
	move	r3,x:-(r6)		;
	move	r2,x:-(r6)		;
	move	r1,x:-(r6)		;
	move	r0,x:-(r6)		;

	rts

	include	'form_corr_matrx.asm'
	include	'k_nn.asm'
	include	'mahalanobis.asm'
