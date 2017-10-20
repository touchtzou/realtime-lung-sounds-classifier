;*********************************************************************************************
; Module Name: lowpass_filter
;*********************************************************************************************
;
; Description: This subroutine filters the input sample in 'x1' with a FIR filter of order 256
;	by the means of the EFCOP unit. So, it initializes EFCOP for FIR stage of RIGHT input
;	sample
;
; Note: The filter used here has the following specifications:
;	A FIR low pass filter with a cutoff freq. of about 50 Hz. The coefficients were
;	obtained using MATLAB at sampling freq. of 8kHz by the windowing method (boxcar window).
;	The filter has a 'Direct form 2 transpose' structure
;
; Input/Output:
;	Input:
;		'x1'=contains the current sample to be filtered
;		FIR_LEN=the order of the filter
;		CHANNELS=the number of input channels 
;		FIR_COEF=the coefficients of FIR filters
;		FIR_FDBA_R=the starting address of the right channel taps
;	Output:
;		'x1'=contains the filtered sample
;
;
;*********************************************************************************************
	

lowpass_filter

		movep   #$000,y:M_FCSR                  ; Reset the EFCOP

		movep   #FIR_LEN-1,y:M_FCNT             ; Set the counter for 256 Coeffs
		movep   y:(r7),y:M_FDBA                 ; R7 = Current FIR Data Pointer
		movep   #FIR_COEF,y:M_FCBA              ; FIR Coeff Pointer
		movep   #$000,y:M_FACR                  ; Clear the FACR
		movep   #$0C1,y:M_FCSR                  ; Enable EFCOP
				;EFCOP Control and Status Register (FCSR)
				; [23:16] = reserved = 0
				; [15] = FDOBF = 0 -> Filter data output buff (FDOR) is empty
				; [14] = FDIBE = 0 -> Filter data input buff (FDIR) is full
				; [13] = FCONT = 0 -> Memory contention has not occured
				; [12] = FSAT = 0 -> Overflow and underflow has not occurred
				; [11] = FDOIE = 0 -> Output Interrupt Disabled
				; [10] = FDIIE = 0 -> Input Interrupt Disabled
				; [9] = reserved = 0
				; [8] = FSCO = 0 -> Sequential coefficients (multichannel mode)
				; [7] = FPRC = 1 -> Initialization Disabled
				; [6] = FMLC = 1 -> Multichannel Mode Enabled
				; [5:4] = FOM = 00 -> Mode 0: Real FIR filter
				; [3] = FUPD = 0 -> Coefficient Update is complete
				; [2] = FADP = 0 -> Adaptive mode disabled
				; [1] = FLT     = 0     -> FIR Filter
				; [0] = FEN     = 1     -> EFCOP enabled	


	movep x1,y:M_FDIR	; Send the sample to be filtered to EFCOP unit
	jclr #15,y:M_FCSR,*	; Wait for Completion of FIR Stage
	movep y:M_FDOR,x1	; Store the filtered sample in x1

 	rts
