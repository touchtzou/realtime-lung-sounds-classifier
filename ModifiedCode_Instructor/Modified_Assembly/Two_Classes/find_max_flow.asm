;****************************************************************************
; Module Name: find_max_flow.asm                                    	    
;**************************************************************************** 
;     FUNCTION:                                                             
;     	This subroutine finds the maximum value in the stored 'inspiratory'
;     flow samples. Then it calculates the thresold value that corresponds
;     to a predetermined percentage given by 'flow_percentage' and returns
;     the calculated threshold via the variable 'x:flow_threshold'.
;                                                                            
;     ENTRY CONDITIONS:                                                     
;	  x:flow_signal-->the starting address of flow signal samples.
;         x:insp_counter--> contains the number of stored insp. flow samples
;		(when downsampled to 125Hz).
;     OUTPUT:
;	     x:max_flow-->found max. insp. flow value.
;	     x:flow_threshold-->the calculated threshold.
;
;****************************************************************************
	org	x:
flow_percentage	equ	0.1   ; Take 10% of the max. insp. flow as threshold.
max_flow	ds	1
flow_threshold	ds	1

	org	p:

find_max_flow
	move	#0,x0		; Initialize max_flow with zero.
	move	x0,x:max_flow	;

	move	x:flow_signal,r0
	move	x:insp_counter,n0

	do	n0,all_insp_flow  ; Go through all of the insp. flow samples.
	move	y:(r0),x0
	move	x:max_flow,a
	sub	x0,a
	jge	not_max_flow
	move	x0,x:max_flow
not_max_flow
	lua	(r0)+,r0
	nop
all_insp_flow
	nop
	move	x:max_flow,b	; The stored flow samples are scaled down by
	asl	#8,b,b		; a factor of 256. Compensate for this scaling
	move	b,x0		; before performing the fractional multiplication.
	move	#flow_percentage,y0
	mpy	x0,y0,a		; After multiplication, apply the scaling down
	asr	#8,a,a		; factor again.
	move	a,x:flow_threshold

	rts
