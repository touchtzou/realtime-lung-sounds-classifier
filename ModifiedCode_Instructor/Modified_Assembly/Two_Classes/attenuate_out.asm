;*************************************************************************
; Module Name: apply_window.asm					       
;*************************************************************************
;  Description:							       
;  This subroutine is used to program the attenuators at the output of
;  the CODEC to prevent any saturation that may result while amplifying
;  the lung sound with the power amplifier that feeds the external
;  speakers. The attenuation value can changed from 0 to -46.5 dB in 1.5
;  dB steps
;*************************************************************************


right_step	equ	0	; the step can take any value between
left_step	equ	18	; 0 (min. atten.) and 31 (max. atten.),
				; where right_step affects the default
				; 'beep sound' output (right chan.) and
				; left_step affects the default 'lung
				; sound' output (left chan.)

right_atten	equ	right_step*$000001
left_atten	equ	left_step*$000001

	org p:

attenuate_out

	clr	b
	move	#right_atten,b1		; restore attenuation to b1
	lsl	#11,b			; shift so lines up with right attenuation bits
	clr	a			
	move	x:CTRL_WD_HI,a1		; restore previous upper control word
	and	#$600700,a		; clear out right & left attenuation bits
	add	b,a			; add new right attenuation to control word

	move	#left_atten,b1
	lsl	#16,b			; shift so lines up with left attenuation
	add	b,a			; left attenuation
	move	a1,x:CTRL_WD_HI
	clr	a
	move	a1,x:CTRL_WD_LO		; clear out lower control word

	jsr	init_codec		; subroutine in ada_init.asm
	rts

