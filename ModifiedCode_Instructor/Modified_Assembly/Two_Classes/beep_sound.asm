;**************************************************************************
; Module Name: beep_sound.asm
;**************************************************************************
; Description: This subroutine is used to generate a beep sound based on 
; 	a digital sine wave generator. The duration of the beep sound is
;	determined by the value of the register n1
;
; Input/Output:
;	Input:
;	   n1=contains a number that determine the beep duration
;	   x:coef,x:s1 and x:s2 are used to generate the next
;	     sine wave sample by the means of a digital oscillator
;	Output:
;	   The generated samples are sent to the output through the 
;	   registers x:TX_BUFF_BASE and/or x:TX_BUFF_BASE+1    
;
; Algorithm Description:
;   The following subroutine calculates the next sinusoidal output value
;   as a function by the digital oscillator given that r0 points to the
;   memory location that contains the "coeff" value followed by the memory
;   location that contains the "s1" value, followed by the memory location
;   that contains the "s2" value.  The formula and block diagram of the
;   oscillator are:
;
;     s1[n] = coeff*s1[n-1] - s2[n-1] = coeff*s1[n-1] - s1[n-2]
;
;                 _______         _______
;                |       |  s1   |       |  s2
;           +--->|  z^-1 |--+--->|  z^-1 |----+
;           |    |_______|  |    |_______|    |
;           |               |                 |
;           |            ___V___           ___V___
;           |           |       |         |       |
;           |           | coeff |         |  -1   |  
;           |           |_______|         |_______|
;           |               |                 |
;           |               |                 |
;           |               |                 |
;           |               +----->( + )<-----+
;           |                        |
;           |                        |
;           +------------------------+---------> sine output
;
;
;**************************************************************************

	org	x:

;***************************
; Constants for oscillators
;***************************

Fs        set     8000.0                        ;sampling freq
PI        set     2.0*@asn(1.0)                 ;compute PI
factor    set     PI/180.0                      ;degrees to radians

		org	x:
; Specification for tone a.
freq_a    set     Fs/4.0                        ;freq in Hz
phi_a     set     360.0*(freq_a/Fs)             ;phi
phase_a   set     90.0                          ;phase angle  
amp_a     set     0.8                           ;amplitude (0-1)
theta2_a  set     (phase_a-(2.0*phi_a))         ;theta2
theta1_a  set     (phase_a-phi_a)               ;theta1
s2_a      set     amp_a*@sin(factor*theta2_a)   ;s2
s1_a      set     amp_a*@sin(factor*theta1_a)   ;s1
coeff_a   set     @cos(factor*phi_a)            ;rcoef in 2:14 format

; Specification for tone b.
freq_b    set     Fs/8.0                        ;freq in Hz
phi_b     set     360.0*(freq_b/Fs)             ;phi
phase_b   set     0.0                           ;phase angle 
amp_b     set     0.8                           ;amplitude (0-1)
theta2_b  set     (phase_b-(2.0*phi_b))         ;theta2
theta1_b  set     (phase_b-phi_b)               ;theta1
s2_b      set     amp_b*@sin(factor*theta2_b)   ;s2
s1_b      set     amp_b*@sin(factor*theta1_b)   ;s1
coeff_b   set     @cos(factor*phi_b)            ;rcoef in 2:14 format

     
DOSC_BUFF_BASE	equ	*
coeff           ds      1       ;Data location for osc a's coeff
s1              ds      1       ;Data location for osc a's sr1
s2              ds      1       ;Data location for osc a's sr2



	org	p:
beep_sound
        move    #6000,n1
        do      n1,end_beep_loop
        jset    #2,x:M_SSISR0,*         ;Wait for frame sync
        jclr    #2,x:M_SSISR0,*         ;Wait for frame sync
        move    #-1,m0                  ;Linear addressing
        move    #DOSC_BUFF_BASE,r0      ;Load pointer to osc coeff, sr1 and sr2
        jsr     sine_oscilator          ;Get next sine value, new value in a
;       move    a,x:TX_BUFF_BASE        ;Put value in left channel tx (if desired)
        move    a,x:TX_BUFF_BASE+1      ;Put value in right channel tx
        nop
end_beep_loop

        rts



sine_oscilator
        move    x:(r0)+,x0              ;Load coeff
        move    x:(r0)+,y0              ;Load s1 into a
        move    x:(r0)-,b               ;Load s2 into b, r0 points to s1
        mpy     x0,y0,a                 ;Get coef*s1 in a in 2:14 format
        subl    b,a                     ;Get (coef*s1 -s2)=sin_val in a
                                        ;in fractional format
        move    a,x:(r0)+               ;Save new s1
        move    y0,x:(r0)               ;Save new s2
        rts

 
