;****************************************************************************
; Module Name: enter_debug_mode.asm
;****************************************************************************
;
; DESCRIPTION: This subroutine is used to write the LPC and autocorr. values
; calculated by this system to an output file using the DEBUG instruction.
; But there is some preparation that must be performed before being able to
; correctly write data to an output file. Firstly, a DEBUG instruction should
; be placed in the program and some designators in certain registers should be
; set. These designators will inform the Debugger 'when' to perform the data
; transfer (defined by the location of the DEBUG instruction in the program),
; from 'where' to get the data (defined by registers r0 & r1), how much data
; to get and where to put the data (defined by register x0). The data is sent
; to an output file whose number is determined using the debugger. The data
; radix and the address of the DEBUG instruction should also be entered by
; the user before executing the program. Here, the calculated LPC & autocorr.
; coeffs. are written to output files with numbers '1' & '2', respectively.
; So before executing the program, two files with these numbers should be
; opened, and the addresses of the DEBUG instructions referring to these
; files should be entered from the menu item: FILE-->OUTPUT-->OPEN. Similarly
; after finishing writing to these files, they should be closed using the
; CLOSE option.
;
;****************************************************************************

	org	x:

file_1	equ	$010000	; Designators of the opened files
file_2	equ	$020000	;

from_p	equ	0	; Define the type of memory from where data is
from_x	equ	1	; going to be read.
from_y	equ	2	;
from_l	equ	3	;

	org	p:

enter_debug_mode
	move	#>(nk+2),x0	; Determine the number of LPC coeffs.
	move	#>60,y0		; to be written to the output file, which is
	mpy	x0,y0,a		; equal to (LPC_order+2)*number_of_segments.
	asr	a
	move	a0,b
	move	#file_1,x0	; For an LPC order of 6, this is equal to 480
	add	x0,b		; words.

	move	b,x0         ; Register x0 contains the Output
			     ; File Number (in the upper 8 bits)
			     ; and the data length (in the lower 16 bits).
			     ; Here, output to file #1 a block of (60*8) words.
	move	#lung_lpc,r0 ; Write data from this address and
	move	#from_y,r1   ; from 'Y' memory.
	debug		     ; Enter the debug mode.


	move	#>(nk+1),x0	; Determine the number of autocorr. coeffs.
	move	#>60,y0		; to be written to the output file, which is
	mpy	x0,y0,a		; equal to (LPC_order+1)*number_of_segments.
	asr	a
	move	a0,b
	move	#file_2,x0	; For an LPC order of 6, this is equal to 420
	add	x0,b		; words.


	move	b,x0		  ; Output to file #2 a block of (60*7) words.
	move	#lung_autocorr,r0 ; Write data from this address and
	move	#from_y,r1	  ; from 'Y' memory.
	debug			  ; Enter the debug mode.
	nop
	
	rts
