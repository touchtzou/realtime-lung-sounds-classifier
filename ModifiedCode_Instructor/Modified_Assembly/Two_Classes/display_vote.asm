;*************************************************************************
; Module Name: display_vote.asm					       
;*************************************************************************
;  Description:							       
;  This subroutine is used to display the votes of the winning class on
;  the LCD.
;*************************************************************************

	org p:
display_vote
       	move	#lcd_vote_strt,r0	; Arrange where to display the
	jsr	lcd_print_line		; votes in the LCD line.

	move	y:resp_cycle_class,n1	; Get the votes of the winner
	move	#phase_votes,r1		; and determine its value so as
	move	y:(r1+n1),a		; to be able to convert the result
					; to ASCII compatible format.

	cmp	#10,a			; Determine the first digit of the
	jlt	zero_digit		; vote and, accordingly, convert it
	cmp	#20,a			; to ASCII format.
	jlt	one_digit		;
	cmp	#30,a			;
	jlt	two_digit		;
	cmp	#40,a			;
	jlt	three_digit		;
	cmp	#50,a			;
	jlt	four_digit		;
	cmp	#60,a			;
	jlt	five_digit		;

	move	#>$36,x0	; 'x0' contains the first digit in the vote
	move	#>$30,y0	; while 'y0' contains the second one.
	jmp	send_char_2lcd	; Display the vote on LCD. Here the vote is
				; '60/60'.
zero_digit
	move	#>$30,x0	; Here, the vote is between 0-9
	add	#$30,a		;
	move	a,y0		;
	jmp	send_char_2lcd

one_digit
	move	#>$31,x0	; The vote is between 10-19.
	add	#(48-10),a	; Convert the second digit to ASCII format
	move	a,y0		; where '48' is the upper 4  bits used for
				; displaying numbers in this format.
	jmp	send_char_2lcd

two_digit
	move	#>$32,x0	; The vote is between 20-29
	add	#(48-20),a	;
	move	a,y0		;
	jmp	send_char_2lcd

three_digit
	move	#>$33,x0	; The vote is between 30-39
	add	#(48-30),a	;
	move	a,y0		;
	jmp	send_char_2lcd	;

four_digit
	move	#>$34,x0	; The vote is between 40-49
	add	#(48-40),a	;
	move	a,y0		;
	jmp	send_char_2lcd

five_digit
	move	#>$35,x0	; The vote is between 50-59
	sub	#50,a		;
	add	#$30,a		;
	move	a,y0		;

send_char_2lcd
	movep	x0,x:M_HDR	; Display the first digit
	bset	#RS,x:M_HDR	; of the vote.
	jsr	short_delay	;
	bset	#EN,x:M_HDR	;
	jsr	short_delay	;
	bclr	#EN,x:M_HDR	;
	jsr	short_delay	;

	movep	y0,x:M_HDR	; Display the second digit.
	bset	#RS,x:M_HDR	;
	jsr	short_delay	;
	bset	#EN,x:M_HDR	;
	jsr	short_delay	;
	bclr	#EN,x:M_HDR	;
	jsr	short_delay	;

       	move	#lcd_vote_end,r0 ; Terminate the vote message.
	jsr	lcd_print_line	 ;
	rts