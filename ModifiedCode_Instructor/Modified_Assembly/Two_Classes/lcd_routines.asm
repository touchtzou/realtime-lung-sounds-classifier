;**************************************************************************************
; Module Name: lcd_routines
;**************************************************************************************
;
; Description: This file contains all the subroutines that are needed to
;	initialize the LCD and send characters to it. The initialization
;	of the LCD requires performing the following steps:
;		1) Wait more than 15 ms after Vdd rises to 4.5 V (power is ON)
;		2) Send the Unlock Command 30h three times
;		3) Send the Function Set command 38h (set interface length, cursor
;			behavior and character font bits)
;		4) Turn the Display OFF 08h
;		5) Turn it ON 0Ch
;		6) Entry Mode Select command 06h
;	After the initialization routine, the LCD is cleared and the cursor is sent
;	home.
;
; Input/Output:
;	Input:
;	  x:M_HPCR=Host Port control register (use all the HPI pins in GPIO mode)
;	  x:M_HDDR=Host port direction Register (all HPI pins are set as output)
;	  r0=contains the address of the first character in the string that
;		is going to be sent to the LCD's specified line
;	  n0=used as a loop counter	
;
;	Output:
;	  x:M_HDR= Host port GPIO data Register (contains the character to
;		be sent to the LCD)
;
;
;**************************************************************************************
	

	org	y:
	include	'lcd_messgs'
M_HDDR   EQU     $FFFFC8        ; Host port GPIO direction Register
M_HDR    EQU     $FFFFC9        ; Host port GPIO data Register

gpio_enable	equ	$0001	; enable HPI pins in GPIO mode and
gpio_direction	equ	$ffff	; set their direction as output

DB0	equ	0	; Define the pins that are connected to the
DB1	equ	1	; LCD's control and data lines
DB2	equ	2
DB3	equ	3
DB4	equ	4
DB5	equ	5
DB6	equ	6
DB7	equ	7
EN	equ	8
RW	equ	9
RS	equ	10
;--------------------------------------------------

	org	p:

lcd_initialize

	movep   #gpio_enable,x:M_HPCR
	movep   #gpio_direction,x:M_HDDR

	bclr	#RW,x:M_HDR	; LCD is used only to send characters to
	bclr	#EN,x:M_HDR
;------------------------------------------------------------

	movep	#$000030,x:M_HDR	; LCD unlock command
	bclr	#RS,x:M_HDR		; (30 hex)

	jsr	short_delay		; A delay loop for the LCD

	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR		; pulse the ENable line
					; so as to tell the LCD that
					; all the data and control signals
					; are ready to be read

	do	#3,wait_5ms
	jsr	long_delay
	nop
	
wait_5ms
;------------------------------------------------------------

	movep	#$000030,x:M_HDR	; LCD unlock command
	bclr	#RS,x:M_HDR		; (30 h)
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	do	#3,wait_128us
	jsr	short_delay
	nop
	
wait_128us

;------------------------------------------------------------
	movep	#$000030,x:M_HDR	; LCD unlock command
	bclr	#RS,x:M_HDR		; (30 h)
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay

;------------------------------------------------------------

	movep	#$000038,x:M_HDR	; Function set command =38h
	bclr	#RS,x:M_HDR		; (4 lines, 5x7 pixels, 8 bit
	jsr	short_delay		; interface)
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR

	jsr	short_delay
;------------------------------------------------------------

	movep	#$000008,x:M_HDR	; Turn the display OFF (08h)
	bclr	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay
;------------------------------------------------------------

	movep	#$00000c,x:M_HDR	; Turn the display ON (0Ch)
	bclr	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR

	jsr	short_delay
;------------------------------------------------------------

	movep	#$000006,x:M_HDR	; Entry Mode Set command (06h)
	bclr	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay
	jsr	lcd_clear
	nop
	rts

;---------------------------------------------------------------
lcd_clear		
	movep	#$000001,x:M_HDR	; Clear screen and send
	bclr	#RS,x:M_HDR		; cursor home (01h)
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	long_delay
	nop
	rts

;---------------------------------------------------------------

lcd_print_line
	move	r0,x:(r6)+		; push to stack
	nop
	do	#7,entire_line		; Print characters to the
	move	y:(r0)+,a0		; specified line until the
	asl	#8,a,a			; character '@=40h' is reached.
	and	#$0000ff,a		; Each memory cell in the DSP
	move	a,b			; is 24 bits wide, so each one
	cmp	#>$40,b			; contains up to 3 characters
	jne	continue_print1
	enddo
	jmp	string_end
continue_print1		; print the first character in the DSP's memory

	movep	a1,x:M_HDR
	bset	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay


	asl	#8,a,a
	and	#$0000ff,a
	move	a,b
	cmp	#>$40,b
	jne	continue_print2
	enddo
	jmp	string_end
continue_print2			; print the second character in the memory
	movep	a1,x:M_HDR	; cell
	bset	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay


	asl	#8,a,a
	and	#$0000ff,a
	move	a,b
	cmp	#>$40,b
	jne	continue_print3
	enddo
	jmp	string_end
continue_print3		; print the third character in the memory cell


	movep	a1,x:M_HDR
	bset	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay

string_end
	nop
	nop
entire_line
	nop
	nop
	move	x:-(r6),r0	; pop from stack
	rts

lcd_2ndline		; Used so as to make the LCD display the characters
			; to its second line
	movep	#$0000c0,x:M_HDR
	bclr	#RS,x:M_HDR

	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay
	nop
	rts
lcd_3rdline		; send characters to LCD's third line
	movep	#$000094,x:M_HDR
	bclr	#RS,x:M_HDR

	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay
	nop
	rts

lcd_4rthline		; send characters to the fourth line
	movep	#$0000d4,x:M_HDR
	bclr	#RS,x:M_HDR
	jsr	short_delay
	bset	#EN,x:M_HDR
	jsr	short_delay
	bclr	#EN,x:M_HDR
	jsr	short_delay
	nop
	rts

;---------------------------------------------------------------
; At 98.304 MHz clock --> 10.17 ns/Instruction_cycle
;---------------------------------------------------------------
long_delay	; This delay is used when clearing the LCD screen

        do	#22,wait_lcd   ; 22 x 7374 x 10.17ns = 1.649 ms
        move    #7374,n0
        rep     n0                      
        nop
wait_lcd
	nop
	rts
short_delay	; This delay is sufficient for most of the other
		; lcd functions (42.7 us)
	move	#4200,n0
	rep	n0
	nop
	nop
	rts
