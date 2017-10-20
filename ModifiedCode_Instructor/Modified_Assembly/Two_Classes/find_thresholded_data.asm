;****************************************************************************
; Module Name: find_thresholded_data.asm                                    	    
;**************************************************************************** 
;     FUNCTION:                                                             
;     	This subroutine finds the starting address and number of samples
;     in the flow signal array of the desired phase (insp. or exp.), whose
;     values are greater than or equal to a threshold value determined by
;     the variable 'x:flow_threshold'. It also returns the starting address
;     and the number of samples of the lung sound array that correspond to
;     the same thresholded flow signal.
;
;                                                                            
;     ENTRY CONDITIONS:                                                     
;	  The variables:flow_start, flow_length, lung_start and lung_length
;	  are used to pass addresses and number of samples of the flow and
;	  lung sound signals found in the resp. phase to be thresholded.
;
;     OUTPUT:
;	  The calculatd new flow and lung array addresses after applying
;	  the threshold are returned via the variables new_flow_start,
;	  new_flow_length, new_lung_start and new_lung_length.
;	    
;****************************************************************************


	org	x:
flow_start	ds	1   ; Start address and number of samples in the 
flow_length	ds	1   ; flow phase to be thresholded, respectively.

lung_start	ds	1   ; Start address and number of samples of the
lung_length	ds	1   ; corresponding lung sound samples, respectively.


new_flow_start	ds	1   ; The new starting addresses and number of
new_flow_length	ds	1   ; samples in the flow and lung signal array
new_lung_start	ds	1   ; after applying the threshold.
new_lung_length	ds	1

new_insp_flow_strt	ds  1	; The 'new' starting address and number of
new_insp_counter	ds  1	; samples in the insp. flow signal to be used
			     	; from now on.

new_insp_lung_strt	ds  1	; The 'new' values that correspond to the insp.
new_pos_sample		ds  1	; lung sound to be used in the classification

new_exp_flow_strt	ds	1 ; The 'new' values related to the desired exp.
new_exp_counter		ds	1 ; flow signal after applying the threshold.

new_exp_lung_strt	ds	1 ; The 'new' values of the exp. lung sound array
new_neg_sample		ds	1 ; to be used in the classification process.

	org	p:

find_thresholded_data

	move	x:flow_threshold,y0
	move	x:flow_start,r0

	move	#0,r1	; 'r1' is used as a counter for the 'total' amount of
			; flow samples that are less than the threshold value.
	move	#0,b	; Use 'b' as a counter of flow samples at the 'beginning'
			; of the phase that are less than the threshold value.
thresholded_flow_strt
	move	y:(r0)+,a  ; Go through the flow array and compare it with the
	abs	a	   ; threshold value. If the flow sample is >= threshold,
	sub	y0,a	   ; then we found the threshold limit. This will give the
	nop		   ; address of first sample in the thresholded flow phase.

	jge	reached_threshold1
	nop
	nop
	inc	b
	lua	(r1)+,r1
	jmp	thresholded_flow_strt
	nop
reached_threshold1
	move	b0,a
	lua	(r0)-,r0	; 'r0' should point to the thresholded flow phase.
	move	r0,x:new_flow_start

	asl	#6,a,a		; To find the starting address of the thresholded
	move	a,x0		; lung sound array (sampled @ 8kHz), multiply with
	move	x:lung_start,a	; the decimation factor 64.
	add	x0,a
	move	a,x:new_lung_start

	move	x:flow_length,a0  ; Point to the last sample in the current
	dec	a		  ; flow phase
	move	a0,x0		  ;
	move	x:flow_start,b	  ;
	add	x0,b		  ;
	move	b,r0		  ;

thresholded_flow_end
	move	y:(r0)-,a   ; Go through the flow array starting from the
	abs	a	    ; last sample in it until we reach the threshold
	sub	y0,a	    ; value. This point will give the address of the
	nop		    ; last sample in the thresholded flow phase.

	jge	reached_threshold2
	nop
	nop
	lua	(r1)+,r1

	jmp	thresholded_flow_end
	nop
reached_threshold2

;--------------------------------------------------------------------
; At this point, r1 contains the number of flow samples skipped over.
; Use it to find the new thresholded flow phase length.
;--------------------------------------------------------------------
    move	r1,x0		; Firstly, check if the value in r1 is
    move	x:flow_length,a	; >= the old flow phase length. If so,
    sub	x0,a		   	; this shows that there is an error in
    jle	restore_old_values	; the calculated values related to the
				; thresholded phase. So, ignore these new
				; values and restore the old ones corres
				; -ponding to the non thresholded phase.

	move	a,x:new_flow_length	

	move	r1,a	; The 'old' lung array length is decremented
	asl	#6,a,a	; by an amount equal to the  total number of flow
	move	a,x0	; samples skipped over times the decimation factor.
	move	x:lung_length,b	;
	sub	x0,b		; 
	move	b,x:new_lung_length

	rts

restore_old_values
	move	x:flow_start,r0
	move	r0,x:new_flow_start
	move	x:flow_length,r0
	move	r0,x:new_flow_length

	move	x:lung_start,r0
	move	r0,x:new_lung_start
	move	x:lung_length,r0
	move	r0,x:new_lung_length

	rts