;************************************************************************
; Module Name: set_classfy_flg.asm
;************************************************************************
; Description:This interrupt service routine is executed by pressing
;  	the push button connected to the external interrupt B (IRQB).
; 	It is used to inform the DSP that the selection of the MENU item
;	is done and that it can excecute the option displayed on the LCD
;	screen.
;;************************************************************************

set_classfy_flg
        bset	#classify_flag,x:flags	; start classification
	rti
