;*************************************************************************
; Module Name: apply_window.asm					       
;*************************************************************************
; Description:							       
;      Applies a Hamming window of 512 points to the array of 	       
;      samples pointed to by the variable x:segment_start. If the      
;      number of samples in the input array is less than the buffer    
;      size then zero padding is done to the rest of the output buffer 
;								       
; Input/Output:							       
;   Input:							       
;	    x:segment_start=contains the address of the array to       
;	      be windowed					       
;	    length_A=contains the buffer size			       
;	    y:window_coeff=contains the window coefficients	       
;   Output:							       
;	x:INA=the starting address of the windowed data      	       
;   Register Usage:						       
;	r0=pointer to the input array				       
;	r1=pointer to window coefficients table			       
;	r2=pointer to output array				       	
;	r3=windowing loop counter				       
;	r4=zero padding loop counter				       	
;								       		
;*************************************************************************

apply_window
	move	x:segment_start,r0          ;pointer to data in X space
	lua	(r0)+,r0
	move	x:(r0),x1
	lua	(r0)+,r0
	move	r0,x:segment_start
	lua	(r0)-,r0
	lua	(r0)-,r0
	move	x:(r0),r0

	move	#length_A,a
	sub	x1,a
	move	a1,r4
	jle	no_zero_pad

	move	x1,r3
	jmp	start_window

no_zero_pad
	move	#length_A,r3
	move	#0,r4
start_window
        move   #window_coeff,r1          ; pointer to window in Y space
        move   #INA,r2          	 ; point to output buffer

   	
	do	r3,window_loop
          move   x:(r0)+,a               ; Get first sample
	  ;asr	#8,a,a			 ; If enabled, the input data will be
	  move	a,x0			 ; scaled down by 1/256 (by shifting
					 ; right 8 bits)

          move   y:(r1)+,y0              ; get first window value         
          mpy    x0,y0,a    	   	 ; apply window, then get next sample

	  ;asl	#1,a,a			 ; If enabled, the windowed samples will be
					 ; scaled up by a factor of 2 before storage
	  move	 a,x:(r2)+ 		    	
                   
window_loop

	move	r4,a
	jeq	padd_zero

 	do	r4,padd_zero
       	  move	#0,y1
	  move	y1,x:(r2)+

padd_zero		               
        
	
	rts
