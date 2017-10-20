;****************************************************************************
; Module Name: resp_phases.asm                                    	    
;**************************************************************************** 
;     FUNCTION:                                                             
;         This subroutine uses the 'number' and 'value' of insp. and exp. 
;	  flow signal samples stored in the memory to calculate the address
;	  of the last sample in each of the 6 respiratory sub-phases (early,
;	  mid  and  late insp./exp. sub-phase), that constitute one full
;	  respiratory cycle. These addresses are used later in determining
;	  the starting address and number of samples found in each of the
;	  ten 25% overlapping segments for each sub-phase.     
;                                                                           
;                                                                            
;     ENTRY CONDITIONS:                                                     
;         r1--> contains the number of 'stored' insp. flow signal samples
;		(when downsampled to 125Hz).            
;         r2--> the  number of 'stored' exp. flow signal samples.
;		(when downsampled to 125Hz).                      
;         flow_signal-->the starting address of flow signal samples.
;         lung_sound-->the starting address of lung sound samples.
;	  pos_sample-->the number of the stored insp. lung sound samples
;		       (sampled @ 8kHz)
;	  neg_sample-->the number of the stored exp. lung sound samples
;		       (sampled @ 8kHz)
;
;     NOTE: At the end of this subroutine, the value in the variable
;     x:lung_sound, defined in 'main.asm', is updated so that it points to
;     the new address of the lung sound array after applying a threshold.
;
;****************************************************************************

resp_phases
	move	r1,x:insp_counter	; Store the number of insp. and exp.
	move	r2,x:exp_counter	; flow signal samples in insp_counter 
					; and exp_counter, respectively. 


	jsr	find_max_flow	; Finds max. insp. flow value used in
				; determining the threshold value to be
				; applied to the stored flow array.

;------------------------------------------------------------------------
; Let us first determine the new addresses and number of samples in the
; thresholded 'inspiratory' flow and lung sound signals using subroutine
; 'find_thresholded_data'.
;------------------------------------------------------------------------
	move	x:flow_signal,r1
	move	r1,x:flow_start
	move	x:lung_sound,r1
	move	r1,x:lung_start
	move	x:insp_counter,r0
	move	r0,x:flow_length
	move	x:pos_sample,r0
	move	r0,x:lung_length
	jsr	find_thresholded_data

	move	x:new_flow_start,r0
	move	r0,x:new_insp_flow_strt
	move	x:new_flow_length,r0
	move	r0,x:new_insp_counter
	move	x:new_lung_start,r0
	move	r0,x:new_insp_lung_strt
	move	x:new_lung_length,r0
	move	r0,x:new_pos_sample

;------------------------------------------------------------------------
; Let us now determine the new addresses and number of samples in the
; thresholded 'expiratory' flow and lung sound signals.
;------------------------------------------------------------------------
	move	x:flow_signal,x0
	move	x:insp_counter,a
	add	x0,a
	move	a,x:flow_start

	move	x:lung_sound,x0
	move	x:pos_sample,a
	add	x0,a
	move	a,x:lung_start

	move	x:exp_counter,r1
	move	r1,x:flow_length
	move	x:neg_sample,r1
	move	r1,x:lung_length

	jsr	find_thresholded_data

	move	x:new_flow_start,r0
	move	r0,x:new_exp_flow_strt
	move	x:new_flow_length,r0
	move	r0,x:new_exp_counter
	move	x:new_lung_start,r0
	move	r0,x:new_exp_lung_strt
	move	x:new_lung_length,r0
	move	r0,x:new_neg_sample

;------------------------------------------------------------------------------
; The new addresses of the thresholded data are used from now on in determining
; the addresses of the respiratory sub-phases.
;------------------------------------------------------------------------------
	move	x:new_insp_counter,r1
	move	x:new_insp_flow_strt,r3
	clr	a 			; Zero the accumulator.

	do	r1,insp_vol	; The area under the flow diagram in 
        move	y:(r3)+,y0	; time domain is the flow volume. As
	add	y0,a            ; a result, adding the samples of  insp. 
insp_vol                        ; flow signal results in a scaled
                         	; value in the accumulator that
                                ; represents the inspiration volume.
		
	rnd	a
	
	move	a1,x:dividend	; The volume of early insp. sub-phase is 30 % of 
        move	#>10,y0   	; the total insp. volume. So, the scaled insp.
        move	y0,x:divisor    ; volume in the accumulator is first divided
             			; by 10 using the routine integer_division. 
                                ; Then the result is multiplied with 3.	
	
	jsr	integer_division ; Call the division subroutine.

	
	move	a0,x0	; The lower portion of accumulator, a0, contains 
              		; the quotient of the division process.
	  
        move	#>3,x1    ; Multiply the result of division with 3 to find
        mpy	x0,x1,a   ; the volume of early insp. sub-phase.
	asr	a
	move	a0,x:early_insp_vol ; Store the calculated early insp. volume

	move	x0,a		; Mid insp. volume is 40 % of the total insp.
	asl	#2,a,a		; volume. So, multiply with 4 to calculate it.
	move	a1,x:mid_insp_vol	; Store mid insp volume.

	move	x:new_exp_counter,r2
	move	x:new_exp_flow_strt,r3
	clr	a
	do	r2,exp_vol	   ; Find the sum of expiratory flow samples
		move	y:(r3)+,y0 ; The result is the scaled exp. volume
		add	y0,a	   ;
exp_vol

	abs	a  ; The scaled exp. volume is negative
                   ; because the exp. flow samples  are
                   ; supposed to be negative. So, find
                   ; the absolute value of this result.
	rnd	a
	move 	a1,x:dividend
	jsr	integer_division

	move	a0,x0
	move	#>3,x1
	mpy	x0,x1,a		
	asr	a		   ; a0 contains the result of multiplication
	move	a0,x:early_exp_vol ; Store the calculated early exp. volume.

	move	x0,a
	asl	#2,a,a
	move	a1,x:mid_exp_vol    ; Store mid exp. volume.


	move	x:early_insp_vol,a  ; Load the accumulator  with the 
       			            ; value of early insp. volume.


	move	x:new_insp_flow_strt,r0
	
early_insp
	move	y:(r0)+,y0     	; Add the positive values of flow
	sub	y0,a  		; signal samples until the summation
	jge	early_insp	; in accumulator becomes negative 
				; (summation becomes equal to or 
                                ; greater than early insp. volume)

	lua	(r0)-,r0
	move	r0,a

	move	x:new_insp_flow_strt,y0 ; Adjust the address found in r0 so
	sub	y0,a		 ; as to make it point to the address of the last
	asl	#6,a,a		 ; sample of early insp. sub-phase and store it 
	move	x:new_insp_lung_strt,y0  ; in "early_insp_end"
	add	y0,a		 ;
	move	a1,x:early_insp_end

	lua	(r0)+,r0
	move	x:mid_insp_vol,a ; Load accumulator  with the value of mid 
        			 ; insp. volume.
mid_insp
	move	y:(r0)+,y0
	sub	y0,a
	jgt	mid_insp
	lua	(r0)-,r0
	move	r0,a
	move	x:new_insp_flow_strt,y0
	sub	y0,a
	asl	#6,a,a
	move	x:new_insp_lung_strt,y0
	add	y0,a
	move	a1,x:mid_insp_end  ;"mid_insp_end" now contains the address of 
                                   ; the last sample of mid insp. lung sound.

	move	x:new_pos_sample,a
	move	x:new_insp_lung_strt,y0 ; Calculate the address of the last sample
        add	y0,a 		; of the insp lung sound and store it in 	
 				; "late_insp_end"

	sub	#>1,a
	move	a1,x:late_insp_end	; The index of the lung sample is found
					; by multiplying the index of flow sample
					; by the decimation factor 64. So the
					; current max. error encountered for second sub-phase
					; in any insp./exp. respiration cycle  is 2*64
					; Plus, an error value of 2*64 will result in the
					; case of making an error while calculating the 
					; flow sample index at which the accumulated volumes
					; are greater than the early insp./exp volumes. No error
					; will result in determining the address of the last sub- 
					; phase, because it is determined using a counter showing
					; the exact number of stored lung sound samples (pos_sample
					; or neg_sample).
	
	move	x:new_exp_flow_strt,r0
	move	x:early_exp_vol,a  ; Load the negative value of early exp.       
     				   ; volume in accumulator.
early_exp
	move	y:(r0)+,y0   ; Summate exp. flow samples until it is equal
	add	y0,a	     ; to the negative of early exp volume (the summation 
	jgt	early_exp    ; in accumulator becomes  negative)

	lua	(r0)-,r0
	move	r0,a

	move	x:new_exp_flow_strt,y0
	sub	y0,a
	asl	#6,a,a
	move	x:new_exp_lung_strt,y0
	add	y0,a
	move	a1,x:early_exp_end ; "early_exp_end" contains the address of the 
                                   ; last sample of early exp. lung sound.
	lua	(r0)+,r0

	move	x:mid_exp_vol,a    ; Load accumulator with the
            			   ; mid. exp. volume
mid_exp
	move	y:(r0)+,y0
	add	y0,a
	jgt	mid_exp
	lua	(r0)-,r0
	move	r0,a

	move	x:new_exp_flow_strt,y0
	sub	y0,a
	asl	#6,a,a
	move	x:new_exp_lung_strt,y0
	add	y0,a
	move	a,x:mid_exp_end	; "mid_exp_end" contains the address of the 
                                ; last sample of mid exp. lung sound.

	move	x:new_neg_sample,a	; Calculate the address of the last sample in
					; exp. lung sound and store it in late_exp_end
	move	x:new_exp_lung_strt,y0 	;
	add	y0,a		   	;
	sub	#>1,a			;
	move	a1,x:late_exp_end	;


	move	x:new_insp_lung_strt,r0	; The address found in lung_sound is updated so
	move	r0,x:lung_sound		; as to point to the new 'thresholded' address.

	rts

	include	'find_max_flow.asm'
	include	'find_thresholded_data.asm'
	include	'integer_division.asm'
