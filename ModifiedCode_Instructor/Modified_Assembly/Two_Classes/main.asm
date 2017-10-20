        page    132,60
;*********************************************************************************
; MODULE NAME: main.asm                              	    		  
;*********************************************************************************
; 
;                                                           		  
; DESCRIPTION: This program initializes the 56311 DSP and CS4218 codec on the
;	Evaluation Module for sampling both of the lung sound and flow signal
;	then it stores them in the arrays "lung_sound" and "flow_signal", 
;	respectively. The sampled lung sound of a full respiration cycle is 
;	divided into 6 sub-phases by the help of the flowmeter signal, then each 
;	sub-phase is divided further into 10 overlapping segments. Each segment
;	is modeled by an Auto Regressive (AR) model of order 6 by the means of the
;	Levinson-durbin algorithm. These feature vectors are used to classify the
;	whole respiratory cycle into two classes: Healthy and pathological. The
;	classification process can be done using two classifiers: k-Nearest
;	Neighbor (K-NN) classifier with Itakura, city-block and Euclidean
;	distance measures, and Minimum distance classifier with Mahalanobis
;	distance measure. The result of the classification process is displayed
;	on a character display (LCD).
;                                                           		    	
;                                		  
;                                                           		
; OPERATING CONDITIONS:                                    
;                                                         
;         	*******************************************         	
;         	 CAUTION: MAXIMUM INPUT VOLTAGE: +/- 2 Vrms               
;         	*******************************************         	        
;               
;		-Sampling frequency: 8 kHz
;               
;		-CODEC INPUT<-derived from the microphone (lung sounds) and
;			      the flowmeter by using the stereo input on
;            		      the CS4218 codec.
;									    
;*********************************************************************************
; Modified on (21-7-2003): The file named 'covar_matrx' was updated by new values
; obtained using a different method. Here, these new matrices were calculated from
; from the scaled LPC coeffs. Next, each one was scaled down by dividing it by its
; max. valued element
;*********************************************************************************
      nolist
      include 'ioequ.asm'
      include 'intequ.asm'
      include 'ada_equ.asm'
      include 'vectors.asm'  
      list
  
;********************************************************************************
; Buffers for talking to the CS4218
;********************************************************************************
; The area between addresses 0-100 is reserved for the software stack pointed to
; by r6
;********************************************************************************
       org    x:100
RX_BUFF_BASE	equ     *
RX_data_1_2	ds	1	; data time slot 1/2 for RX ISR (left audio)
RX_data_3_4	ds	1	; data time slot 3/4 for RX ISR (right audio)

TX_BUFF_BASE	equ	*
TX_data_1_2	ds	1	; data time slot 1/2 for TX ISR (left audio)
TX_data_3_4	ds	1	; data time slot 3/4 for TX ISR (right audio)

RX_PTR          ds      1	; pointer for RX buffer
TX_PTR          ds      1	; pointer for TX buffer


CTRL_WD_12      equ     MIN_LEFT_ATTN+MIN_RIGHT_ATTN+LIN2+RIN2
CTRL_WD_34      equ     MIN_LEFT_GAIN+MIN_RIGHT_GAIN

;********************************************************************************
;  External Memory Usage
;********************************************************************************
;  Y_START = starting address for external memory  (Y:$40000 in this case)
;  Y_SIZE = size of external memory (64K words, mapped from Y:$40000 to Y:$4ffff)
;********************************************************************************
Y_SIZE          EQU     $010000         ; External memory size (64K Y: WORDS)
Y_START         EQU     $040000		; Start of external address
LINEAR          EQU     $FFFFFF         ; Linear addressing mode
AAR0V           EQU     $040821         ; Value programmed into AAR0
  					; Compare 8 most significant bits
					; Look for a match with address
  					; Y:0000 0100 xxxx xxxx xxxx xxxx
					; No packing, no muxing, Y enabled
				 	; P and X disabled, AAR0 pin active low
					; Asynchronous SRAM access
BCRV             EQU   $012421		; Value programmed into BCR
  					; 1 wait state for all AAR regions
;********************************************************************************

flags		ds	1

;-------------------------------------------------------------------------;
; Bit definition of the "flags" variable  	    	   		  ;
;-------------------------------------------------------------------------;
; +--------------------------------------------------------------------+
; |B23..B17|B16 B15 B14 B13 B12 B11 B10 B9 B8 B7 B6| B5 B4 B3 B2 B1 B0 |                   
; +--------------------------------------------------------------------+                   
;   |    |   |   |   |   |   |   |   |   |  |  |  |   |  |  |  |  |  +-continue_storing
;   |    |   |   |   |   |   |   |   |   |  |  |  |   |  |  |  |  +----synch_flag    
;   |    |   |   |   |   |   |   |   |   |  |  |  |   |  |  |  +-------noise_flag     
;   |    |   |   |   |   |   |   |   |   |  |  |  |   |  |  +----------insp_flag         
;   +-+--+   |   |   |   |   |   |   |   |  |  |  |   |  +-------------exp_flag            
;     |      |   |   |   |   |   |   |   |  |  |  |   +----------------calssify_flag	   
;  not used  |   |   |   |   |   |   |   |  |  |  +--------------------itakura_flag
;	     |   |   |   |   |   |   |   |  |  +-----------------------mahalanob_flag
;            |   |   |   |   |   |   |   |  +--------------------------euclidean_flag
;	     |   |   |   |   |   |   |   +-----------------------------cityblock_flag	
;            |   |   |   |   |   |   +---------------------------------record_flag
;	     |   |   |   |   |   +-------------------------------------listen_flag
;            |   |   |   |   +-----------------------------------------displayonce_flag
;            |   |   |   +---------------------------------------------one_msj_flag  
; 	     |   |   +-------------------------------------------------filter_flag     
;	     |   +-----------------------------------------------------nofilter_flag    
;	     +---------------------------------------------------------filter_status
;
;-------------------------------------------------------------------------;      
continue_storing	equ	0
synch_flag	equ	1

noise_flag	equ	2	; A flag used  to show whether the flow signal
			        ; sample is noisy or not.
insp_flag	equ	3	; Flags used to show the current phase of the
exp_flag	equ	4	; lung sound being sampled.
classify_flag	equ	5	; Used to start the classification process,
				; otherwise the device will only output the
				; lung sounds through the speaker

itakura_flag	equ	6	; used to select Itakura distance measure
mahalanob_flag	equ	7	; used to select Mahalanobis distance measure
euclidean_flag	equ	8	; used to select Euclidean distance measure
cityblock_flag	equ	9	; used to select city block distance metric
record_flag	equ	10		; start recording to the external RAM
listen_flag	equ	11		; plays the recorded data
displayonce_flag	equ	12	; used to display an LCD message only once
one_msj_flag	equ	13	; used to display a message once
filter_flag		equ	14	; applies a digital FIR filter
nofilter_flag		equ	15  ; removes the filter
filter_status		equ	16  ; shows whether the filter is going to be
				    ; used or not (0-->remove fltler,1-->use it)

start_address	equ	$804	; Starting addresses of the arrays that
lung_sound	ds	1	; contain lung sound and flow signal
flow_signal	ds	1	; samples respectively (2052.th location).
				; Note: the address found in lung_sound will
				; be changed, if necessary, by the subroutine
				; 'resp_phases' so that it points to the starting
				; address of lung sound array after applying a threshold.
flow_sample	ds	1
;*****************************************************************************
; The following two variables are used by the subroutine "threshold_test"
; to determine whether the sample is noisy or not
;*****************************************************************************
threshold_pos	equ	0.0003	; These symbols are used to define the 
threshold_neg	equ	-0.0003	; threshold values which are used to reject 
                                ; the samples that are suspected to be noisy.
                                ; The resolution of codec is 16 bit, so step 
                                ; size for a full scale of +/-2.8V is 5.6/(2^16)
                                ; volt. In this fractional fixed point DSP,
				; this full scale will correspond to fractional
				; numbers in the range [-1,1). Thus, the positive
				; threshold will correspond to approximately
				; threshold_pos*abs(full scale) volts.

;****************************************************************************
; The following variables are used by subroutine "resp_phases" to find the 
; ten 25% overlapping segments from which LPC coefficients are going to be
; extracted
;****************************************************************************
                                                 
insp_counter	ds	1	; the number of insp. and exp. flow samples when
exp_counter	ds	1		; sampled @ 125Hz (by decimation), respectively

early_insp_vol	ds	1
mid_insp_vol	ds	1


early_exp_vol	ds	1
mid_exp_vol	ds	1

early_insp_end	ds	1
mid_insp_end	ds	1
late_insp_end	ds	1

early_exp_end	ds	1
mid_exp_end	ds	1
late_exp_end	ds	1

;*****************************************************************************
; The following variables are used by subroutine find_10_segments to calculate
; the starting address and number of samples per segment
;*****************************************************************************
phase_start	ds	1
phase_end	ds	1 
segment_length	ds	1
overlap_length	ds	1
segments_info	equ     *	; Array used to store the starting address and number
		ds	20	; of samples per segment of the ten 25% overlapping
				; segments
;****************************************************************************
; The following 2 variables are used by subroutine "integer_division" to
; perform a signed integer division
;****************************************************************************
dividend	ds	1
divisor		ds	1

;*******************************************************************************
; The following variables are used by "apply_window" to apply a hamming window
; of length 512. Then "autocorr" routine is applied to the buffer whose starting
; address is pointed to by "INA"..Finally "durbin" routine is used to calculate
; the LPC coefficients of order nk
;*******************************************************************************
segment_start	ds	1
length_A	set	512		 ; array size of 512 samples	


nk		equ		6	 ; 6th order LPC analysis
model_error	ds		1	 ; LPC modeling error

INA	equ	*
	ds	length_A+nk+2		; buffer for the lung sound samples
					; and the calculated autocorrelation
					; coefficients


;******************************************************************************
; EFCOP Variables
;******************************************************************************

CHANNELS                equ             2              ; There are 2 FIR channels
FIR_LEN                 equ             256            ; There are 256 FIR coeff.

FIR_COEF                equ             $600   ; EFCOP FIR Coeffs. (Y Mem)
FIR_FDBA_L              equ             $600   ; EFCOP FIR Data Buffer Ptr for Left Channel
FIR_FDBA_R              equ             $700   ; EFCOP FIR Data Buffer Ptr for Right Channel
FDBA_PTR                equ             0      ; Pointer to saved FDBA values (Y mem.)

			org	x:FIR_FDBA_L
			ds		256

			org	x:FIR_FDBA_R
			ds		256

;*****************************************************************************************
; The area between addresses x:$23c (INA+length_A+nk+3) and x:$600 (address of filter
; buffer) is allocated for the new variables to be added to the program ( a maximum space
; of 964 words)..So, for proper operation, any new variable should be appended to the 
; following data segment 
;*****************************************************************************************

	org	x:INA+length_A+nk+3

;*********************************************************************************
; The area between x:$804 (decimal 2052) and x:$bfff (decimal 49151) is allocated 
; for the storage of lung sound samples
;*********************************************************************************


;********************************************
;	 Y memory map:			    *
;********************************************

;*********************************************************************************
; The area between y:$804 (decimal 2052) and y:$13b8 (decimal 5048) is allocated 
; for the storage of flow signal samples
;*********************************************************************************


	org	y:$13c4	; corresponds to 5060.th location
;*********************************************************************************
; The following 2 variables are used by 'lpc_transfer' to transfer lpc coefficients
; to the array y:lung_lpc
;*********************************************************************************
next_seg_lpc	ds	1	; contains address of the next lpc storage area
next_seg_corr	ds	1	; contains address of the next autocorrelation area


lung_lpc	equ	*		; an array of size (number of segments*model order+2)
		ds	60*(nk+2)	; used to store the calculated LPC coefficients plus
					; the modeling error of each segment

lung_autocorr	equ	*		; an array of size (number of segments*model order+1)
		ds	60*(nk+1)	; used to store the calculated autocorrelation
					; coefficients

;*********************************************************************************
; The following memory area is allocated for the storage of the training vectors
; and the inverse covariance matrices so as to be used as the reference libraries
; in the classification process
;*********************************************************************************
		
		nolist
database	equ	*		
		include	'database.asm'

	
covar_matrx	equ	*

		include	'covar_matrx.asm'   ; memory space of length 6*ncl*(nk+1)*(nk+1)

mean_features	equ	*

		include	'mean_features.asm' ; memory space of length 6*ncl*(nk+1)
	
		org	y:FDBA_PTR
		ds		2	   ;  FDBA_PTR+0   ->      FIR_FDBA_L
					   ;  FDBA_PTR+1   ->      IIR_FDBA_R

;-------------------------------------------------
; The coefficients of the Hamming window
;-------------------------------------------------
window_coeff  		equ   	* 
			nolist
			include	'window_coeff.asm'
			list
window_coeff_end	equ	*

;-------------------------------------------------
; The coefficients of the FIR filters
;-------------------------------------------------
		org             y:FIR_COEF
		include 'bandpass_coef.asm'
		include 'lowpass_coef.asm'
		list
;**************************************************************************************
; The area between addresses y:$201 (window_coeff_end+1) and y:$600 (FIR ceoff. address) 
; is allocated for the new variables to be added to the program ( a maximum space of 
; 1023 words)..So, for proper operation, any new variable should be appended to the 
; following data segment
;**************************************************************************************

	org	y:window_coeff_end+1

ncl			equ	2	; The number of classes
phase_votes		equ	*
			ds	ncl
resp_cycle_class	ds	1	; contains the calculated class of the
					; respiration cycle

;******************************************************************************
; The interrupt IRQB will set the "classify_flag" which will start the 
; classification process, while IRQD is used to select the distance measure.
;******************************************************************************

        org     p:$0
        jmp     START

        org     p:$12                   ; IRQB
	jsr	set_classfy_flg		; start classification

	org     p:$16                   ;IRQD is used to select the distance
        jsr	distance_metric         ;measure to be used in the classification


;**************************************************************
; START OF MAIN PROGRAM					      *
;**************************************************************

        org     p:$100		; entry point of the program (256.th location)

START

	movep   #$040007,x:M_PCTL      	; PLL (8 x 12.288Mhz) = 98.304Mhz
       	movep   #AAR0V,x:M_AAR0         ; AAR0 as shown above
        movep   #BCRV,x:M_BCR           ; One ext. wait state for Asynch SRAMs
       
        ori     #3,mr              	; mask interrupts	
	movep   #$000618,X:M_IPRC       ; IRQB/IRQD/SSI level 3 int level sensitive
        movep   #$FF310C,x:M_CRB0   	; Enable the SSI interrupts

        movec   #0,sp	              	; clear hardware stack pointer
        move    #0,omr             	; operating mode 0
        move    #$0,r6             	; initialize stack pointer

        move    #LINEAR,m0            	; linear addressing
        move   	#LINEAR,m1 		;
        move    #LINEAR,m2   		;
	move    #LINEAR,m3 		;
        move    #LINEAR,m4 	  	;
	move    #LINEAR,m5 		;
	move    #LINEAR,m6		;

       	movep   #TCSR_LED_OFF,x:M_TCSR0 ; Make sure the LEDs are off
	movep   #TCSR_LED_OFF,x:M_TCSR1	;
	movep   #TCSR_LED_OFF,x:M_TCSR2	;


	move	#$1,r5
	move	r5,x:flags	; Initialize these flags by setting high
				; "continue_storing" and resetting the other
				; flags


;*********************************************************
; R7 - Holds Pointer Value for current FDBA Buffer (EFCOP)
;*********************************************************
	move    #FDBA_PTR,r7            ; Base pointer for FDBA values (X mem)
	move    #1,m7                   ; Set the buffer to 2

;--------------------------
; Codec Initialization
;--------------------------
	move    #RX_BUFF_BASE,x0
	move    x0,x:RX_PTR             ; Initialize the rx pointer
	move    #TX_BUFF_BASE,x0
	move    x0,x:TX_PTR             ; Initialize the tx pointer
	
        jsr     ada_init           	; initialize codec

;--------------------------------------------------------
; Generate a beep sound to indicate system initialization
;--------------------------------------------------------

        move    #coeff_b,x0
        move    x0,x:DOSC_BUFF_BASE     ; Load coeff, s1 and s2 values (which
        move    #s1_b,x0		; are needed by the digital oscillator 
        move    x0,x:DOSC_BUFF_BASE+1   ; sine wave generator to generate the 
        move    #s2_b,x0		; next sine sample from the previous 
        move    x0,x:DOSC_BUFF_BASE+2   ; two samples
        jsr     beep_sound
	jsr	attenuate_out
;--------------------------------------------------------------------
; The following delay loop is entered so as to give a reasonable time
; for the user to read the displayed messages
;--------------------------------------------------------------------

	jsr	wait_2restart
	jsr	lcd_initialize	; initialize the LCD module

;-----********-----------********----------welcome_msj
;-----********-----------********----------welcome_msj

       	move	#lcd_welcome10,r0	; r0 points to the first
	jsr	lcd_print_line		; character to be displayed on 
	jsr	lcd_2ndline		; the LCD

       	move	#lcd_welcome11,r0	
	jsr	lcd_print_line		; send the character string to
	jsr	lcd_3rdline		; the LCD's third line

       	move	#lcd_welcome12,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline	; choose the fourth line

       	move	#lcd_welcome13,r0
	jsr	lcd_print_line


;-----********-----------********----------welcome_msj
;-----********-----------********----------welcome_msj


;*******************************************************************
; 		EFCOP initialization
;*******************************************************************


	move	#>FIR_FDBA_L,r0
	move	#>FIR_FDBA_R,r1
	
	
	do #FIR_LEN,initial_taps
	nop
        jset    #2,x:M_SSISR0,*    ; wait for RX frame sync 
        jclr    #2,x:M_SSISR0,*    ; wait for RX frame sync

        move    x:RX_BUFF_BASE,a   ; receive left
        move    x:RX_BUFF_BASE+1,b ; receive right

	nop
	nop
	;;;;neg	b		; negate the flow so that the insp.
				; and exp. flow samples become positive
				; and negative ones, respectively
	;;;;;;nop
	move	a,x:(r0)+	   ; initialize the samples to be used 
	move	b,x:(r1)+	   ; in FIR filtering
initial_taps
	nop
	nop

;****************************************
; Setup EFCOP Data Buffers (and Pointers)               
;****************************************

	move    #FDBA_PTR,r3    ; Base pointer for FDBA values (X mem)
	move    #FIR_FDBA_L,r0
	move    r0,y:(r3)+
		
	move    #FIR_FDBA_R,r0
	move    r0,y:(r3)+
		
;************************
; Setup Channels in EFCOP
;************************
	movep   #CHANNELS-1,y:M_FDCH   ; # of EFCOP Channels
			  ; [23:12] = reserved = 0
			  ; [11:8] = FDCM = 0000 -> Decimation Factor 0
			  ; [7:6] = reserved = 0
			  ; [5:0] = FCHL

	move	#start_address,r5
	move	r5,x:lung_sound    ; Starting address of lung sound samples.
	move	r5,x:flow_signal   ; Starting address of flow samples.
	move	r5,r0		   ; r0 points to lung sound array.
     	   

	move	r5,r3		   ; r3 points to flow signal array.

	move	#0,r1 ; r1 and r2 are used to count the number of inspiratory
	move	#0,r2 ; and expiratory lung signal samples, respectively		
	move	#1,r4

;**********************************************************
; Infinite loop - Waiting for reception of required  data 
; (the transmit and receive  interrupts are enabled)  	  
;**********************************************************
	move	#0,y1
	move	y1,x:pos_sample
	move	y1,x:neg_sample

	move	#Y_START,r5	; initialize r5 with the starting address of
				; the external SRAM (used to record the lung
				; sound samples if the record_flag is set)

loop

        jset    #2,x:M_SSISR0,*    ; wait for RX frame sync 
        jclr    #2,x:M_SSISR0,*    ; wait for RX frame sync
	clr	a
	clr	b
        move    x:RX_BUFF_BASE,a   ; this sample corresponds to lung sound
        move    x:RX_BUFF_BASE+1,b ; this sample corresponds to flow signal
	nop
	nop
	;;;;neg	b		; negate the flow so that the insp.
				; and exp. flow samples become positive
				; and negative ones, respectively
	;;;;nop

	btst	#listen_flag,x:flags	; If both of the listen_flag and the 
	jcc	dont_listen		; classify_flag are set then this shows 
	btst	#classify_flag,x:flags	; that the lung sound recorded to the ext. 
	jcc	dont_listen		; SRAM should be sent to the speaker, otherwise
	movep   #$000804,X:M_IPRC 	; continue executing the program. If the flag is
					; set then disable interrupts that may cause 
					; improper operation during sound playing process 
	btst	#displayonce_flag,x:flags
	jcs	skip_listen_msg

;-----********-----------********----------listening_msj
;-----********-----------********----------listening_msj
      	jsr	lcd_clear
       	move	#lcd_listen60,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_listen61,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_listen62,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_footer,r0	
	jsr	lcd_print_line
	move	#>0,r0
;-----********-----------********----------listening_msj
;-----********-----------********----------listening_msj

	bset	#displayonce_flag,x:flags
skip_listen_msg
	move	r0,a			; r0 is used to downsample the signal sent
	cmp	#0,a			; to the speaker by a factor of two. Thus,
	jne	downsample_out		; each recorded sample is sent only if r0
	move	#>1,r0			; is equal to zero, otherwise nothing is sent
					; to the output. So, the value of r0 is changed
	move	y:(r5)+,b		; between 0 and 1 at each interrupt.

	move	b,x:TX_BUFF_BASE	  ; send recorded lung sound to output (left channel)
	move	b,x:TX_BUFF_BASE+1  ; send recorded lung sound right channel (if desired)



	lua	(r4)+,r4
	move	r4,a			; if we reached the end of the ext. SRAM
	cmp	#Y_SIZE,a		; then stop sending samples to the output
	jle	loop			;

;-----********-----------********----------listeningended_msj
;-----********-----------********----------listeningended_msj

      	jsr	lcd_clear
       	move	#lcd_listen70,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_listen71,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_listen72,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_footer,r0	
	jsr	lcd_print_line

;-----********-----------********----------listeningended_msj
;-----********-----------********----------listeningended_msj

	jmp	START			;
downsample_out
	move	#>0,r0
	jmp	loop


dont_listen
	move	a,x0	; lung sound
	nop
	move	b,y0	; flow signal
	nop

	btst	#filter_flag,x:flags
	jcc	check_nofilter
	btst	#classify_flag,x:flags
	jcc	check_status
	bclr	#classify_flag,x:flags
	bset	#filter_status,x:flags
	jmp	check_status

check_nofilter
	btst	#nofilter_flag,x:flags
	jcc	check_status
	btst	#classify_flag,x:flags
	jcc	check_status
	bclr	#classify_flag,x:flags
	bclr	#filter_status,x:flags
check_status
	btst	#filter_status,x:flags
	jcc	dont_filter

;---------------------------------------------------------
; PROCESS LEFT INPUT (lung sound)
;---------------------------------------------------------

	move	a,x1
	nop		
	jsr	bandpass_filter	    ; Filter the lung sound
	move	x1,x0		    ; and return the result in x1
	
	movep   y:M_FDBA,y:(r7)+    ; Update FIR Data Pointer

;-----------------------------------------------------------
; PROCESS RIGHT INPUT (flow signal)
;-----------------------------------------------------------

	move	b,x1
	nop	
	jsr	lowpass_filter		; Filter the flow signal
	move	x1,y0			; and return the result in x1

	movep   y:M_FDBA,y:(r7)+        ; Update FIR Data Pointer

;-----------------------------------------------------------


dont_filter
      move    x0,x:TX_BUFF_BASE 	; pass lung sound to output (left channel)
;	move	x0,x:TX_BUFF_BASE+1	; send lung sound to right channel (if desired)

	btst	#classify_flag,x:flags	; check the classify flag,
	jcc	loop 			; if this flag is set then the
					; classification process will start &
					; the next instruction will be executed.
					; If it is reset then just output the lung
					; sound and return to the start of this loop


	btst	#record_flag,x:flags	; If record_flag is set then start recording
	jcc	not_recording		; the lung sound to the ext. SRAM, next
	movep   #$000000,X:M_IPRC 	; disable the interrupts that may cause 
					; improper operation.
	btst	#displayonce_flag,x:flags
	jcs	skip_record_msg

;-----********-----------********----------recording_msj
;-----********-----------********----------recording_msj

      	jsr	lcd_clear
       	move	#lcd_record30,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_record31,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


       	move	#lcd_record32,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_footer,r0	
	jsr	lcd_print_line
	move	#>0,r0

;-----********-----------********----------recording_msj
;-----********-----------********----------recording_msj

	bset	#displayonce_flag,x:flags
skip_record_msg
	move	r0,a			; Downsample the lung sound by a factor of 2,
	cmp	#0,a			; thus select only one sample out of 2 samples
	jne	downsample_in		; and store it at the address pointed to by
	move	#>1,r0			; address register r5
	move	x0,y:(r5)+
	lua	(r4)+,r4		; The ext. SRAM is of size 64k words, so check 
	move	r4,a			; if we reached the end of the memory by using
	cmp	#Y_SIZE,a		; r4 as a counter. The total duration of the 
					; records sound is 16 seconds at a sampling
	jle	loop			; frequency of 8 kHz.


;-----********-----------********----------recordingended_msj
;-----********-----------********----------recordingended_msj
      	jsr	lcd_clear
       	move	#lcd_record40,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_record41,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


       	move	#lcd_record42,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_record43,r0	
	jsr	lcd_print_line

;-----********-----------********----------recordingended_msj
;-----********-----------********----------recordingended_msj


	jmp	START
downsample_in
	move	#0,r0
	jmp	loop



not_recording

	move	x:flags,a	; if none of the distance measures is
	and	#$3c0,a		; chosen then don't start the classification
	cmp	#0,a		; process and return back to the start of 
	jeq	loop		; loop



	btst	#one_msj_flag,x:flags
	jcs	check_synch
	movep   #$000000,X:M_IPRC       ; disable any interrupt that originates from
					; IRQB/IRQD after the classify_flag is set which
					; means that the distance measure to be used in
					; classification process (by pressing IRQD) must
					; be chosen before the classify_flag is set (by 
					; pressing IRQB)

;-----********-----------********---------startbreath_msj
;-----********-----------********---------startbreath_msj

      	jsr	lcd_clear
       	move	#lcd_breathc0,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_breathc1,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_breathc2,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_breathc3,r0	
	jsr	lcd_print_line
	move	#start_address,r0
;-----********-----------********---------startbreath_msj
;-----********-----------********---------startbreath_msj

	bset	#one_msj_flag,x:flags
	org	x:

semi_cycle	equ	5000		; a value used to define the number of min. samples
					; in a cycle to decide whether it is a semicycle or not


pos_sample	ds	1		; the number of inspiratory flow samples keeping 
					; their sign without change (pos.) for consecutive samples
 					; (sampled @ 8kHZ, this will be equal to the number of insp.
					; lung sound samples)
neg_sample	ds	1		; the number of exp. flow samples keeping their 
					; sign without change (neg.) for consecutive samples
 					; (sampled @ 8kHZ, this will be equal to the number of exp.
					; lung sound samples)

	org	p:
check_synch
	btst	#synch_flag,x:flags	; Check the synch_flag to
	jcs	start_storing		; see if it is the beginning of the desired 
					; inspiration cycle. If synch_flag is set then
					; we are at the beginning of an inspiration 
          			        ; cycle, so we can start storing flow and lung
					; sound signals

	jsr	threshold_test		; Check if the sample is noisy or not.
	bclr	#noise_flag,x:flags	; If the sample is noisy then reject it and
	jcs	loop			; return.



	btst	#23,x:flow_sample	; Check the sign bit to decide if the 
	jcc	suspected_insp		; sampled flow signal corresponds to insp. or exp. cycle.
					; (if positive then it is insp. else it is exp.)
	move	x:pos_sample,a		; A semi cycle is considered a false one. So if the pos.
	cmp	#semi_cycle,a		; flow samples are less than the max. number of samples  
	jge	real_insp_cycle		; in a semi_cycle, then reject this cycle and start over again
					; Else, it is a real inspiration cycle (@ sampling freq.of 8kHZ)
	move	#0,y1			;
	move	y1,x:pos_sample		;

real_insp_cycle
	move	x:neg_sample,a0		; we have already passed over a real insp. cycle, so now
	inc	a			; we are in an exp. cycle and the counter of exp. samples
	move	a0,x:neg_sample		; is incremented accordingly (@ sampling freq. of 8kHz).
	nop
	move	x:neg_sample,a		; check if we passed through enough number of exp. samples
	nop				; that can help us determine whether we passed over a real
	cmp	#semi_cycle,a		; exp. cycle (@ 8kHz).
	jlt	loop
	bset	#exp_flag,x:flags	; Set the exp_flag if the flow is in an 
                           		; exp. cycle.
	jmp	loop
suspected_insp
	move	x:flags,a	; If both the exp_flag and insp_flag are set 
	and	#$18,a		; then check if we are still in an undesired 
	cmp	#$18,a		; exp. cycle, if we are not then this means we
	jeq	start_synch 	; have skipped over the undesired insp. and exp. 
				; cycles. As a result, the next flow sample will 
                        	; be the first one of the desired insp. cycle  
                         	; and the storing of these samples will begin.

	


	move	x:neg_sample,a	; check if we passed over a real exp. cycle
	cmp	#semi_cycle,a	; (@ 8kHz)
	jlt	semi_exp_cycle	;

start_synch
	bset	#synch_flag,x:flags	; Setting synch_flag shows that the next 
					; samples are the desired ones and they are  
                              	    	; going to be stored in memory.

	bclr	#insp_flag,x:flags	; insp_flag only will be needed in the storage
						; process(no need for exp_flag)

	move	#0,y1		
	move	y1,x:pos_sample		; Initialize these variables with zero so as to
	move	y1,x:neg_sample		; use them in the storage process. At the end
						; of the storage process, these variables will
						; indicate the number of the stored insp. & exp.
						; lung sound samples (sampled @ 8kHz), respectively.
						; On the other hand, x:insp_counter & x:exp_counter
						; will give the number of the stored insp. and exp.
						; flow samples (downsampled to 125Hz), respectively.

	jmp	insp_flow	; This branch is taken  for the first 
                                ; sample of the flow signal or if the synch_flag is set.

semi_exp_cycle
	move	#0,y1
	move	y1,x:neg_sample	; we have passed over a false exp. cycle so start over
	move	x:pos_sample,a0	; by counting the insp. flow samples (@ 8kHZ)
	inc	a		;
	move	a0,x:pos_sample	;
	nop			;

	move	x:pos_sample,a
	nop
	cmp	#semi_cycle,a
	jlt	loop
	nop
	bset	#insp_flag,x:flags
	jmp	loop

;-------------------------------------------------------------------------------
; We have passed over the undesired insp and/or exp cycle..So from now on we 
; can store the insp. then the exp flow/lung samples constituting a full resp.
; cycle
;-------------------------------------------------------------------------------

start_storing
	jsr	threshold_test		; determine whether the flow sample
	bclr	#noise_flag,x:flags	; is noisy or not
	jcs	loop			;
	
	btst	#23,x:flow_sample	; the first sample to be stored must be
	jcc	positive_flow		; pos. (insp. cycle). So, if the first sample
	btst	#insp_flag,x:flags	; is negative then reject it until getting
	jcc	loop			; a pos. flow sample
	
	move	x:pos_sample,a		; for elimination of the undesired semi-insp cycles,
	cmp	#semi_cycle,a		; check the counter of the insp. samples (@ 8kHz).
	jge	insp_cycle_stored
	bclr	#insp_flag,x:flags
	move	#0,y1			; if the stored insp. samples refer to the undesired
	move	y1,x:pos_sample		; semi-cycle, then update the address pointers so as
	move	#start_address,r0	; to remove these unwanted samples and rewrite over 
	move	r0,r3			; them with new data (@ 8kHz)
	jmp	loop			;

insp_cycle_stored
	
	bclr	#continue_storing,x:flags ; Reset continue_storing to indicate 
                                    ; that we have finished  sampling
                                    ; the desired insp. cycle.
	move	x:neg_sample,a0
	inc	a
	move	a0,x:neg_sample
	jmp	exp_flow
positive_flow
	btst	#continue_storing,x:flags ; If continue_storing is
	jcc	full_resp_stored	  ; reset, then this shows that we have passed through 
				; the desired insp. cycle during the first breath and this 
               			; shows that we are in the insp. cycle of the second
           			; breath. But since one breath is sufficient for our 
          			; purpose, the sampling and storing process is 
         			; terminated at this point.


	bset	#insp_flag,x:flags 	; Set the insp_flag to show that the flow is
                              		; in an insp. cycle.	
	move	x:pos_sample,a0
	inc	a
	move	a0,x:pos_sample
	jmp	insp_flow

full_resp_stored
	move	x:neg_sample,a		; if the stored exp. cycle samples refer to the
	cmp	#semi_cycle,a		; wanted exp. cycle then end the storage process
	jge	storage_ended		; (@ 8kHz)


	move	#0,y1
	move	y1,x:neg_sample	;shows that we have passed over a false exp. cycle (@ 8kHz)


	move	#start_address,r0	; If the stored exp. cycles refer to the undesired
	move	r0,r3			; semi-exp-cycle then update the addresses so as 
	move	r0,a			; to make them point to the starting address of 
	nop				; the memory allocated for the storage of the exp.
	move	x:pos_sample,y1		; lung and flow signals. Then write over these unwanted
	add	y1,a			; samples with new ones (@ 8kHz).
	move	a1,r0			; 
	move	r1,y1			; 
	move	r3,a			;
	nop				;
	add	y1,a			;
	nop				;
	move	a1,r3			;
	jmp	loop			;


;------------------------------------------
; Store the exp. lung and/or flow samples
;------------------------------------------
exp_flow
	lua	(r4)+,r4	; downsample the flow signal so that we store a flow sample  
	move	r4,b		; out of 64 samples (decimation in time). If the counter
	cmp	#64,b		; of sampled flow samples is not equal to 64, then only 
	jne	store_only_lung	; the lung sample is stored. Otherwise, both of the lung
				; and flow samples are stored

	lua	(r2)+,r2
	movep   #TCSR_LED_OFF,x:M_TCSR0	; Turn off the led that indicates insp. phase, then
	movep   #TCSR_LED_ON,x:M_TCSR2	; turn on the other led that indicates an exp. phase
	jmp	store_both_samples	;
	

;------------------------------------------
; Store the insp. lung and/or flow samples
;------------------------------------------
insp_flow:
	lua	(r4)+,r4
	move	r4,b
	cmp	#64,b
	jne	store_only_lung

	lua	(r1)+,r1
	movep   #TCSR_LED_OFF,x:M_TCSR2
	movep   #TCSR_LED_ON,x:M_TCSR0
store_both_samples:
	move	#1,r4	
	move	x:flow_sample,a	    ; scale down the flow samples before storage
	asr	#8,a,a		    ; by a factor of 8 bits

	move	a,y:(r3)+	    ; Store flow signal samples in memory.


	move	r3,b		    ; If we reached the end address of the 
	cmp	#$13b9,b	    ; memory allocated for flow signal then stop
	jeq	storage_ended	    ; storing


store_only_lung
	move	x0,x:(r0)+  	; Store lung sound sample in memory.


	move	r0,b		; If we reached the end address of the 
	cmp	#$c000,b	; memory allocated for lung signal then stop
	jeq	storage_ended	; storing
	jmp	loop


;--------------------------------------------------------------------------
; We have stored a full resp. cycle. So, the storage process is terminated
; and the classification algorithm is executed next
;--------------------------------------------------------------------------
storage_ended

;----------------------------------------------------------------------------
; Blink led then generate a beep sound to indicate End of Storage
;----------------------------------------------------------------------------

  	movep   #TCSR_LED_OFF,x:M_TCSR0 ; Make sure the LEDs are off
	movep   #TCSR_LED_OFF,x:M_TCSR1	;
	movep   #TCSR_LED_OFF,x:M_TCSR2	;
	jsr	blink_led		; blink LED to Indicate End of Storage

        move    #coeff_a,x0
        move    x0,x:DOSC_BUFF_BASE     ; Load oscillator coeff 
        move    #s1_a,x0
        move    x0,x:DOSC_BUFF_BASE+1   ; Load s1 and s2 which are needed to  
        move    #s2_a,x0		; generate a new sine value
        move    x0,x:DOSC_BUFF_BASE+2   ; 
        jsr     beep_sound
;----------------------------------------------------------------------------

	movep   #$03330c,x:M_CRB0 ; Stop sampling/storing signals by masking the
                      	      	  ; interrupts that correspond to the serial port
				  ; ESSI

	move    #LINEAR,m7	  ; use r7 in linear mode from now on


	jsr	resp_phases		; Use this subroutine to calculate the address
					; boundaries of each respiratory sub-phase. This
					; can be calculated by finding the volume of the flow
					; rate signal with respect to time. However, instead
; of finding the volumes, these addresses can be calculated crudely by  taking only
; the number of insp. or exp. lung sound samples into account. To accomplish this,
; rename the file called 'resp_phases(no_volume).asm' with 'resp_phases.asm' and replace
; it with the existing file named resp_phases.asm and assemble the main.asm file again.
; However, calculating the address boundaries by this way requires 'reforming' the
; reference libraries found by MATLAB. Therefore, the MATLAB code used to obtain the reference
; libraries should be changed accordingly so that the address boundaries of each
; respiratory sub-phase are calculated without taking the flow volumes into account.


	move	#lung_lpc,r2		; the starting address of the lpc
	move	r2,y:next_seg_lpc	; array
       
	move	#lung_autocorr,r2	; the starting address of the autocorr.
	move	r2,y:next_seg_corr	; coefficients
	
;-------------------------------------------------------------------------------
	move	x:lung_sound,r0     ; The start and end addresses of the early 
	move	r0,x:phase_start    ; insp. sub-phase are used to calculate ten 
	move	x:early_insp_end,r1 ; overlapping segments between them.
	move	r1,x:phase_end	    ; Here, lung_sound will point to the address
				    ; of lung array 'after' applying a threshold.
	
	jsr	find_10_segments ; This routine is used to segment the stored lung
                           	 ; sounds to 25% overlapping segments which in turn
                          	 ; are used to calculate LPC coefficients.  

                                
	move	#segments_info,r2
	move	r2,x:segment_start

; Repeat the following block of code n times (the default is n=10),
; where n is the number of segments per respiratory sub-phase
	do	#n,lpc_loop1
	jsr	apply_window	   ; Apply Hamming window to each segment
	move 	#length_A,r2	   ; Initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr	   ; Calculate autocorr. coefficients
	jsr	durbin  ; Find the LPC coefficients of the lung samples 
                        ; using Durbin's recursive algorithm

	jsr	lpc_transfer	; transfer LPC coefficients of each segment
				; and pad them to the previously calculated 
				; ones in the array starting at 'y:lung_lpc'


lpc_loop1

;-------------------------------------------------------------------------------


	move	x:early_insp_end,r0 ; Calculate the ten overlapping segments of
	lua	(r0)+,r0	    ; the  mid insp. sub-phase.
	move	r0,x:phase_start    ;
	move	x:mid_insp_end,r1   ;
	move	r1,x:phase_end      ;
	jsr	find_10_segments    ;
	move	#segments_info,r2
	move	r2,x:segment_start
	do	#n,lpc_loop2
	jsr	apply_window
	move 	#length_A,r2	   ; initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr
	jsr	durbin
	jsr	lpc_transfer	


lpc_loop2

;-------------------------------------------------------------------------------
	move	x:mid_insp_end,r0  ; Calculate the addresses of the ten
	lua	(r0)+,r0           ; overlapping segments of late insp. sub-
	move	r0,x:phase_start   ; phase.
	move	x:late_insp_end,r1 ;
	move	r1,x:phase_end     ;
	jsr	find_10_segments   ;
	move	#segments_info,r2
	move	r2,x:segment_start
	do	#n,lpc_loop3
	jsr	apply_window
	move 	#length_A,r2	   ; initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr
	jsr	durbin
	jsr	lpc_transfer	



lpc_loop3

;-------------------------------------------------------------------------------

	move	x:late_insp_end,r0 ;  Find the segments of early exp. sub-phase. 
	lua	(r0)+,r0	   ;
	move	r0,x:phase_start   ;
	move	x:early_exp_end,r1 ;
	move	r1,x:phase_end     ;
	jsr	find_10_segments   ;
	move	#segments_info,r2
	move	r2,x:segment_start
	do	#n,lpc_loop4
	jsr	apply_window
	move 	#length_A,r2	   ; initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr
	jsr	durbin
	jsr	lpc_transfer	



lpc_loop4

;-------------------------------------------------------------------------------
	move	x:early_exp_end,r0 ; Find the segments of mid exp. sub-phase
	lua	(r0)+,r0	   ;
	move	r0,x:phase_start   ;
	move	x:mid_exp_end,r1   ;
	move	r1,x:phase_end     ;
	jsr	find_10_segments   ;
	move	#segments_info,r2
	move	r2,x:segment_start
	do	#n,lpc_loop5
	jsr	apply_window
	move 	#length_A,r2	   ; initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr
	jsr	durbin
	jsr	lpc_transfer	


lpc_loop5

;-------------------------------------------------------------------------------
	move	x:mid_exp_end,r0   ; Find the segments of late exp. sub-phase
	lua	(r0)+,r0	   ;
	move	r0,x:phase_start   ;
	move	x:late_exp_end,r1  ;
	move	r1,x:phase_end     ;
	jsr	find_10_segments   ;
	move	#segments_info,r2
	move	r2,x:segment_start
	do	#n,lpc_loop6
	jsr	apply_window
	move 	#length_A,r2	   ; initialize with array length
	move 	#nk,r3		   ; and maximum lag (AR model order)
	jsr	autocorr
	jsr	durbin
	jsr	lpc_transfer		


lpc_loop6

;-------------------------------------------------------------------------------

	move	#$0,r6		; r6 will be used here as software stack pointer
     				; from x:0 to x:100

	move	#lung_lpc,r1		; load the address of the first vector 
	move	r1,y:next_lpc_lung	; to be classified by subroutine 'k_nn'

	move	#lung_autocorr,r1	; load the address of the first autocorrelation 
	move	r1,y:next_corr_lung	; vector


	move	#0,x0
	move	#phase_votes,r1		
	rep	#ncl			; initialize the sub-phase votes with zero
	   move	x0,y:(r1)+		; (class-0)
	
	move	#database,r1		; load the starting address of the training 
	move	r1,y:next_database	; data (used if the subroutine k_nn is called)
	
	move	#0,r0			; start with the first segment ( used if 
	move	r0,y:segment_no		; Mahalanobis subroutine is called)


;-------------------------------------------------------------------------------
; Each respiratory cycle consists of 6 sub-phases. So, repeat the following sub-  
; phases classification process 6 times thus adding the votes of these sub-phases
;-------------------------------------------------------------------------------
	move	#1,r7
all_resp_cycle
	jsr 	find_phase_vote		; classify each respiratory sub-phase

	lua	(r7)+,r7
	move	r7,b
	
	cmp	#6,b
	jle	all_resp_cycle

;-------------------------------------------------------------------------------

	move	#phase_votes,r1		; get the calculated sub-phase votes
	move	#0,b
	move	y:(r1)+,a
	do	#ncl-1,are_votes_equal	; Check to see if the votes are equal.
	move	y:(r1)+,x0		; If they are so then increment the
	sub	x0,a			; counter 'b'.
	jne	not_equal_votes
	inc	b
not_equal_votes
	nop
are_votes_equal
	nop


	move	b0,a		; if the votes are all equal then display
	move	#>(ncl-1),x0	; an error message indicating that an unresolved
	sub	x0,a		; situation has occurred
	jne	diagnosis_result
	

;-----********-----------********---------error_msj
;-----********-----------********---------error_msj

      	jsr	lcd_clear	; clear the LCD screen
       	move	#lcd_error0,r0	; and display a message
	jsr	lcd_print_line	; that notifies that the 
	jsr	lcd_2ndline	; votes are equal and that no
       	move	#lcd_error1,r0	; diagnosis could be made
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_error2,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_error3,r0	
	jsr	lcd_print_line
	move	#start_address,r0

;-----********-----------********---------error_msj
;-----********-----------********---------error_msj

	jmp	test_end

diagnosis_result
	move	#phase_votes,r1		; get the calculated sub-phase votes
	move	r1,y:votes_array	;

	jsr	find_max_indx		; find the class of the respiration 
					; cycle with the maximum vote

	move 	y:voting_winner,r1	; Store the found respiration cycle class in the 
	move	r1,y:resp_cycle_class	; variable y:resp_cycle_class

;-----********-----------********---------diagnosis_msj
;-----********-----------********---------diagnosis_msj

	move	y:resp_cycle_class,a	; if the calculated class is equal to
	cmp	#1,a			; one then the diagnosis result is
	jne	ill_subject		; HEALTHY. So, display the message
					; that reflects this result on LCD
	jsr	lcd_clear		; (class-1)
	
      	move	#lcd_end,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_diagnose,r0	
	jsr	lcd_print_line
	jsr	lcd_3rdline
	move	#lcd_healthy,r0
	jsr	lcd_print_line
	jsr	lcd_4rthline
	jsr	display_vote
	jmp	test_end
	
ill_subject			; if the calculated class label
	jsr	lcd_clear	; equals zero, then display a message
       	move	#lcd_end,r0	; that shows that the diagnosis result
	jsr	lcd_print_line	; is PATHOLOGICAL (class-0)
	jsr	lcd_2ndline
       	move	#lcd_diagnose,r0	
	jsr	lcd_print_line
	jsr	lcd_3rdline
	move	#lcd_pathology,r0
	jsr	lcd_print_line
	jsr	lcd_4rthline
	jsr	display_vote
;-----********-----------********---------diagnosis_msj
;-----********-----------********---------diagnosis_msj

test_end		; blink the led for a short period of time

	do	#3,blinkled_delay
	jsr	wait_2restart
blinkled_delay
	nop
	;jsr	enter_debug_mode	; If enabled, this subroutine is used to write
					; the calculated LPC & autocorr. coeffs. from
					; DSP'S memory to external two output files
	nop
	nop
	stop	; enter the low power standby  mode until the pushbutton
		; connected to IRQA is pressed

	nop
	nop
	nop

;-----********-----------********---------restart_msj
;-----********-----------********---------restart_msj

      	jsr	lcd_clear		; clear the LCD screen
       	move	#lcd_restart0,r0	; and display a message
	jsr	lcd_print_line		; that notifies that the 
	jsr	lcd_2ndline		; system is restarting
       	move	#lcd_restart1,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_restart2,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_restart3,r0	
	jsr	lcd_print_line
	move	#start_address,r0

;-----********-----------********---------restart_msj
;-----********-----------********---------restart_msj

	jsr	wait_2restart
	nop
	jmp	START
wait_2restart	; a delay used to blink the led for a short priod of time
        do	#4095,wait_2read   ; 4095 x 65536 x 10.17ns = 2.73 sec
        move    #65536,x0
        rep     x0                      
        nop
wait_2read
	rts



 	include 'ada_init.asm'
	include	'attenuate_out.asm'
	include	'beep_sound.asm'
	include	'lcd_routines.asm'
	include	'bandpass_filter.asm'
	include	'lowpass_filter.asm'
	include	'set_classfy_flg.asm'
	include	'distance_metric.asm'
	include	'threshold_test.asm'
	include	'blink_led.asm'
	include	'resp_phases.asm'
	include	'find_10_segments.asm'
	include	'apply_window.asm'
	include 'autocorr.asm'
	include 'durbin.asm'
	include	'lpc_transfer.asm'

	include	'find_phase_vote.asm'
	include	'find_max_indx.asm'
	include	'matrx_multply.asm'	
	include	'fraction_division.asm'
	include	'display_vote.asm'
	include	'enter_debug_mode.asm'
        end

