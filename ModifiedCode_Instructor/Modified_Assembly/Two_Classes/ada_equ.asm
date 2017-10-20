        page    132,60
;****************************************************************************
;   ADA_EQU.ASM
;   Initialization constants to facilitate initialization of the CS4218
;
;   Copyright (c) MOTOROLA 1998
;            Semiconductor Products Sector 
;            Digital Signal Processing Division
;
;****************************************************************************
;
; Control word examples:
;
; Select LIN2 and RIN2 as inputs, set left and right attentuation to minimum,
; with minimum left and right gain:
;     CTRL_WD_12      equ     MIN_LEFT_ATTN+MIN_RIGHT_ATTN+LIN2+RIN2
;     CTRL_WD_34      equ     MIN_LEFT_GAIN+MIN_RIGHT_GAIN
;
; Select LIN2 and RIN2 as inputs, set left and right attentuation to 7.5dB
; (attentuation is in 1.5dB steps), with minimum left and right gain:
;     CTRL_WD_12      equ     5*LEFT_ATTN+5*RIGHT_ATTN+LIN2+RIN2
;     CTRL_WD_34      equ     MIN_LEFT_GAIN+MIN_RIGHT_GAIN
;

;Upper 16 bits of control word CTRL_WD_12
MASK            equ     $400000
DO1             equ     $200000
MAX_LEFT_ATTN   equ     $1f0000         ; -46.5 dB
MAX_RIGHT_ATTN  equ     $00f800         ; -46.5 dB
LEFT_ATTN       equ     $010000		; Usage: (val)*LEFT_ATTN where val=0 to 31
RIGHT_ATTN      equ     $000800		; Usage: (val)*RIGHT_ATTN where val=0 to 31
MIN_LEFT_ATTN   equ     $000000         ; 0 dB
MIN_RIGHT_ATTN  equ     $000000         ; 0 dB
MUTE            equ     $000400
LIN2            equ     $000200         ; use LIN2 on EVM
RIN2            equ     $000100         ; use RIN2 on EVM

;Lower 16 bits of control word CTRL_WD_34
MAX_LEFT_GAIN   equ     $f00000         ; 22.5 dB
MAX_RIGHT_GAIN  equ     $0f0000         ; 22.5 dB
LEFT_GAIN       equ     $100000 	; Usage: (val)*LEFT_GAIN where val=0 to 15
RIGHT_GAIN      equ     $010000		; Usage: (val)*RIGHT_GAIN where val=0 to 15
MIN_LEFT_GAIN   equ     $000000         ; 0 dB
MIN_RIGHT_GAIN  equ     $000000         ; 0 dB
