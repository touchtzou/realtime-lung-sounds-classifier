;***************************************************************************
; Module Name: find_10_segments.asm
;***************************************************************************
; Description:                                                             
;          The find10segments routine uses the start and end addresses of   
;          any sub-phase to segment the  area between them into ten 25%        
;          overlapping segments.                                           
;									   	
;  INPUT/OUTPUT:							   
;	   Input:							   
;		x:phase_start = contains starting address of the sub-phase     
;		x:phase_end = contains the ending address of the sub-phase 	   
;	  Output:							   
;		x:segment_info = contains the calculated values		   
;									   
;  Register Usage:							   
;	   r1 = temporary storage					   
;	   r2 = pointer to the array x:segments_info 			   
;									   
;  Algorithm:                                                              
;         1.The total number of samples in the frame to be segmented is    
;           calculated.                                                    
;         2.To find the number of samples in each of the ten 25%           
;           overlapping segments , the number found in step.1 is divided    
;           by 8 and the result is stored in "segment_length"              
;         3.To calculate the number of 25% overlapping samples, the        
;           result found in step-2 is divided by 4 and stored in           
;           "overlap_length"                                               
;         4.Store the calculated starting addresses and number of samples  
;	    per segment in the array "x:segments_info" , which consists    
;	    of 10 value pairs..The first element in the pair is the        
;	    starting address of the segment, while the second value is      
;	    the number of samples in it.				   
;									   
;***************************************************************************

find_10_segments
   move	#segments_info,r2
   move	x:phase_end,a            ; Calculate the number of samples to be
   move	x:phase_start,x0 	 ; segmented.
   sub	x0,a        		 ;
	

   asr	#3,a,a                  ; Divide the total  number of samples in each  
                             	; frame by 8 to find the number of samples 
                                ; per segment  (by shifting right 3 bits) and 
   move	a1,x:segment_length     ; store this result in the variable 
                                ; "segment_length"


   asr	#2,a,a                  ; Divide the  number of samples per segment
                             	; by four to find the number of overlapping
                                ; samples (by shifting 2 bits right)
   move	a1,x:overlap_length     ; and store it in "ovelrap_length"


    
   do	#9,find9segments        ; Find the first 9 segments and calculate LPC 
                                ; coefficients for each. So, repeat the following 
				; block of code 9 times
   move	x:phase_start,r1
   move	r1,x:(r2)+
   	
   move	x:segment_length,r1
   move	r1,x:(r2)+
   
   move	x:phase_start,a   
   move x:segment_length,x0
   add	x0,a
   move	x:overlap_length,x1
   sub	x1,a
   move	a,x:phase_start		; "phase_start" now contains the starting address
                                ; of the next overlapping segment.
find9segments: 
   move	a,x:(r2)+        	; 'A' now contains the starting address of 
                                ; the next overlapping segment.

   move	x:phase_end,x0
   sub	x0,a		; The last segment must end at the address
   neg	a		; pointed to by phase_end. So, this segment is
		   	; calculated separately.
   move	a,x:(r2)+	;

;****************************************************************************
; End of find_10_segments subroutine.                                       *
;****************************************************************************

	rts
