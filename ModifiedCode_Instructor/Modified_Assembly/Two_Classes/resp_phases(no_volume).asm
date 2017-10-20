;****************************************************************************
; Module Name: resp_phases.asm                                    	    
;**************************************************************************** 
;     FUNCTION:                                                             
;         This subroutine uses 'number' of insp. and exp. lung sound samples
;	  stored in the memory to calculate the ending address for each of
;	  the 6 respiratory sub-phases (early, mid  and  late insp./exp. sub-
;         phase), that constitute one full respiratory cycle. These addresses
;	  are used later in determining  the starting address and number of
;         samples found in each of the ten 25% overlapping segments for each
;	  sub-phase.
;                                                                           
;                                                                            
;     ENTRY CONDITIONS:                                                     
;         r1--> contains the number of insp. flow signal samples
;		(when downsampled to 125Hz).            
;         r2--> the  number of exp. flow signal samples.
;		(when downsampled to 125Hz).  
;	  x:pos_sample-->contains the number of insp. lung sound samples
;		(when sampled @ 8kHz).
;	  x:neg_sample-->contains the number of exp. lung sound samples
;		(when sampled @ 8kHz).
;         x:lung_sound-->the starting address of lung sound samples. 
;
;     NOTE: At the end of this subroutine, the value in the variable
;     x:lung_sound, defined in 'main.asm', is updated so that it points to
;     the new address of the lung sound array after applying a threshold.
;
;****************************************************************************
resp_phases
	move	r1,x:insp_counter	; Store the number of insp. and exp.
	move	r2,x:exp_counter	; flow signal samples in insp_counter
					; and exp_counter, respectively (not
					; used in this subroutine)

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

	move	x:new_pos_sample,r1	; The area under the flow diagram in time
	move	r1,x:dividend	; domain is the flow volume. The volume of 
        move	#>10,y0   	; early insp. sub-phase is 30 % of the total insp.
        move	y0,x:divisor    ; volume. So, the ending point (length) of the
             			; early insp. sub-phase will be approximately
				; equal to (number_of_insp_lung_samples*0.3). The
				; number of insp.  samples is first divided by
				; 10 using the routine integer_division. Then
				; the result is multiplied with 3.

	jsr	integer_division ; Call the division subroutine.

	
	move	a0,x0	; The lower portion of accumulator a0 contain 
              		; the quotient of the division process.
	  
        move	#>3,x1    ; To find the address of last point of early insp.
        mpy	x0,x1,a   ; sub-phase, first multiply the result of division with
	asr	a	  ; 3.
	move	a0,b	  ; 
	move	x:new_insp_lung_strt,y0	; Next, add the resulting value to the
	add	y0,b	; start address of the stored & thresholded lung sound array

	move	b1,x:early_insp_end	; Store the calculated sub-phase address

        move	#>7,x1   ; Mid insp. volume corresponds to the next 40 % 
        mpy	x0,x1,a  ; of the total insp. volume. So, multiply the result
	asr	a	 ; of the above divison with 7 and add the result to
	move	a0,b	 ; the starting address of stored lung samples array
	nop		 ;
	add	y0,b	 ;
	nop
	move	b1,x:mid_insp_end ; Store address of last sample in mid. insp.
				  ; sub-phase.

	move	x:new_pos_sample,a    	  ; Calculate the address of the last sample
	move	x:new_insp_lung_strt,y0	  ; of the insp lung sound array and store it
	add	y0,a		  	  ; in "late_insp_end".
	sub	#>1,a
	move	a1,x:late_insp_end

	move	x:new_neg_sample,r1
	move 	r1,x:dividend
	jsr	integer_division

	move	a0,x0
	move	#>3,x1
	mpy	x0,x1,a		
	asr	a		   

	move	a0,b		    	; Adjust the value found in 'b' so as to
	move	x:new_exp_lung_strt,y0  ; make it point to the address of the last
	add	y0,b		    	; sample of early exp. sub-phase.

	move	b1,x:early_exp_end ; "early_exp_end" contains the address of the 
                                   ; last sample of early exp. lung sound.

	move	#>7,x1
	mpy	x0,x1,a		
	asr	a
	move	a0,b
	add	y0,b

	move	b1,x:mid_exp_end ; "mid_exp_end" now contains the address of 
                                 ; the last sample of mid exp. lung sound.

	move	x:new_neg_sample,a	; Calculate the address of the last sample 
	move	x:new_exp_lung_strt,y0  ; in exp. lung sound array and store it in
	add	y0,a		   	; late_exp_end.
	sub	#>1,a			;
	move	a1,x:late_exp_end  	;

	move	x:new_insp_lung_strt,r0	; The address found in lung_sound is updated so
	move	r0,x:lung_sound		; as to point to the new 'thresholded' address.

	rts

	include	'find_max_flow.asm'
	include	'find_thresholded_data.asm'
	include	'integer_division.asm'
