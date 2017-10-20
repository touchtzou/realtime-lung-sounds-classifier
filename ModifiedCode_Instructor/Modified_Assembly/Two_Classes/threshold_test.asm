;***********************************************************************
; Module Name: threshold_test.asm
;***********************************************************************
;
; Description: The threshold_test routine checks whether the sampled
; flow signal is above or below the acceptable positive and negative   
; threshold values, respectively. If it is equal to or within these
; threshold values then this sample will be considered to be noisy and
; a flag indicating this will be set.	 	  	
;
;***********************************************************************

threshold_test
	move	y0,x:flow_sample ; The sampled flow singal is 
      				 ; stored in flow_sample
	btst	#23,y0
	jcs	check_neg
	move	y0,a
	sub	#threshold_pos,a ; Check to see if the flow sample is 
            			 ; greater than the positive threshold
                                 ; or not. If the sample is above the
                                 ; threshold then it is not noisy one.
	jle	noisy_sample
	rts	

check_neg
	move	y0,a
	sub	#threshold_neg,a ; If the sample value lies between the 
            			 ; positive and negative threshold values
	jge	noisy_sample
	rts
noisy_sample
	bset	#noise_flag,x:flags ; then it is considered to be a noisy
                               ; sample and it is rejected by setting
                               ; the noise_flag
	rts
