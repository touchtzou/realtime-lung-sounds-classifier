;***************************************************************************
; Module Name: find_max_indx.asm
;***************************************************************************
; Description: 	this routine goes through the array which contains the votes
;		for each class, then it finds the maximum vote and the class
;		that it refers to.	
;
; Input/Output:
;	Input:
;		y:votes_array=contains the votes of all classes
;		
;	Output:
;		y:max=variable used to store the current max. vote
;		y:voting_winner=used to store the class index with
;			       the maximum vote
;
; Register Usage:
;	r0 & n1=used together to generate displacement for address generation
;	  	of different elements within votes_array
;
;	r1=pointer to votes_array
; 
;***************************************************************************
	org	y:

max		ds	1	; Used to determine the class with the
				; maximum vote

	
voting_winner	ds	1	; The class index with the maximum votes
votes_array	ds	1	; An array contains the votes of different
				; classes


	org	p:
;***************************************************
;   now find max class votes for the current segment
;***************************************************
find_max_indx
	move	r0,x:(r6)+	; push to stack
	move	r1,x:(r6)+	;
	move	n1,x:(r6)+	;
	

	move	#0,x0
	move	x0,y:max
	move	x0,y:voting_winner
	move	y:votes_array,r1
	move	#0,r0
	
find_vote
	move	r0,n1
	move	y:(r1+n1),x0	; x0 contains the element vote[r1+n1]

	move	y:max,a		; 'a' contains the maximum vote (until now)

			
	sub	x0,a		; if the vote is less than 'max' then skip over 
	jge	skip_over	; the current vote and get the vote of the next
				; class otherwise the current vote is accepted as	
	move 	x0,y:max	; the maximum vote (for now..)

	move	r0,y:voting_winner	; voting_winner contains the index of the winner
					; class
skip_over
	lua	(r0)+,r0	; Update the index of the array vote[]
	move	r0,n1		;

	move	r0,a		; Repeat the above segment of code 'ncl' times
	cmp	#ncl,a		;
	jlt	find_vote	;

	move	x:-(r6),n1	; pop from the stack
	move	x:-(r6),r1
	move	x:-(r6),r0

	rts


