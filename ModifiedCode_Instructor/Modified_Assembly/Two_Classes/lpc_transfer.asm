;****************************************************************************
; Module Name: lpc_transfer.asm
;****************************************************************************
; 
; Description:This routine transfers the calculated lpc and autocorrelation
;	 coefficients of each segment and stores them sequentially to the
;	 array y:lung_lpc and y:lung_autocorr, respectively
;
;****************************************************************************
lpc_transfer
	move 	y:next_seg_lpc,r1
	move	#acoeffs,r0	; starting address of the segment's lpc

	move	#nk+1,r2	; counter for the number of LPCs to be 
				; transfered
	do	r2,lpc_move
	move	y:(r0)+,x0
	move	x0,y:(r1)+
lpc_move
	move	x:model_error,x0	; Append the modeling error to the
	move	x0,y:(r1)+		; calculated LPC array
	move	r1,y:next_seg_lpc	; Update the address of the 
					; storage area

	move	y:next_seg_corr,r1
	move	#r,r0
	move	#nk+1,r2
	
	do	r2,autocorr_move	; transfer the calculated autocorr.
	move	x:(r0)+,x0		; coefficients
	move	x0,y:(r1)+
autocorr_move

	move	r1,y:next_seg_corr

	rts
