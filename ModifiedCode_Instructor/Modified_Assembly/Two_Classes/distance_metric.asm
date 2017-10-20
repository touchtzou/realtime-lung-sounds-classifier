;************************************************************************
; Module Name: distance_metric.asm
;************************************************************************
; Description:This interrupt service routine is executed by pressing
;  	the push button connected to the external interrupt D (IRQD).
; 	It is used to select the desired distance measure to be used 
;	in the classification process by the rest of the program. The
;	user may also choose to record a total of 64k lung sound samples
;	to the external SRAM. Then he may listen to this recorded sound
;	offline
;	There are eight options that could be selected:
;		-K-nn with Itakura distance measure
;		-K-nn with Euclidean distance measure
;		-K-nn with city-block distance measure
;		-Minimum distance classifier with Mahalanobis metric
;		-record 16 seconds of lung sound to the ext. SRAM
;		-listen to the recorded sound
;		-apply a digital filter on both the lung and flow signals
;		-remove the digital filter
;************************************************************************

distance_metric

	bclr	#mahalanob_flag,x:flags
	jcs	set_record
	bclr	#record_flag,x:flags
	jcs	set_listen	
	bclr	#listen_flag,x:flags
	jcs	set_euclid
	bclr	#euclidean_flag,x:flags
	jcs	set_cityblock
	bclr	#cityblock_flag,x:flags
	jcs	set_itakura	
	bclr	#itakura_flag,x:flags	
	jcs	set_filter
	bclr	#filter_flag,x:flags
	jcs	set_nofilter
	bclr	#nofilter_flag,x:flags
	bset	#mahalanob_flag,x:flags	

;-----********-----------********---------mahalanob_msj
;-----********-----------********---------mahalanob_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_mahalanobb0,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline


      	move	#lcd_mahalanobb1,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline


       	move	#lcd_mahalanobb2,r0	
	jsr	lcd_print_line
        jsr	delay_2select ; a delay to insert enough time
			      ; between the user's selections
	nop

;-----********-----------********---------mahalanob_msj
;-----********-----------********---------mahalanob_msj

	rti
set_record
	bset	#record_flag,x:flags

;-----********-----------********----------recordselect_msj
;-----********-----------********----------recordselect_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_record20,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

       	move	#lcd_record21,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_footer,r0	
	jsr	lcd_print_line
        jsr	delay_2select

	nop
;-----********-----------********----------recordselect_msj
;-----********-----------********----------recordselect_msj

	rti
set_listen	
	bset	#listen_flag,x:flags
;-----********-----------********----------listen_msj
;-----********-----------********----------listen_msj
;        ori     #3,mr         ; mask interrupts	
	nop
      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_listen50,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

       	move	#lcd_listen51,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_footer,r0	
	jsr	lcd_print_line
        jsr	delay_2select

	nop
;-----********-----------********----------listen_msj
;-----********-----------********----------listen_msj

	rti
set_euclid
	bset	#euclidean_flag,x:flags
;-----********-----------********----------euclid_msj
;-----********-----------********----------euclid_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_euclid80,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

      	move	#lcd_knn,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_euclid81,r0	
	jsr	lcd_print_line
	jsr	delay_2select       

	nop
;-----********-----------********----------euclid_msj
;-----********-----------********----------euclid_msj

	rti
set_cityblock
	bset	#cityblock_flag,x:flags
;-----********-----------********---------cityblock_msj
;-----********-----------********---------cityblock_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_cityblocka0,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

      	move	#lcd_knn,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_cityblocka1,r0	
	jsr	lcd_print_line
	jsr	delay_2select 

	nop
;-----********-----------********---------cityblock_msj
;-----********-----------********---------cityblock_msj
	rti
set_itakura
	bset	#itakura_flag,x:flags
;-----********-----------********---------itakura_msj
;-----********-----------********---------itakura_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_itakur90,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

      	move	#lcd_knn,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_itakur91,r0	
	jsr	lcd_print_line
        jsr	delay_2select

	nop
;-----********-----------********---------itakura_msj
;-----********-----------********---------itakura_msj

	rti


set_filter
	bset	#filter_flag,x:flags
;-----********-----------********---------filter_msj
;-----********-----------********---------filter_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_filterd0,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

      	move	#lcd_filterd1,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_footer,r0	
	jsr	lcd_print_line
        jsr	delay_2select

	nop
;-----********-----------********---------filter_msj
;-----********-----------********---------filter_msj

	rti

set_nofilter
	bset	#nofilter_flag,x:flags
;-----********-----------********---------filter_msj
;-----********-----------********---------filter_msj

      	jsr	lcd_clear
       	move	#lcd_header,r0
	jsr	lcd_print_line
	jsr	lcd_2ndline
       	move	#lcd_filtere0,r0
	jsr	lcd_print_line
	jsr	lcd_3rdline

      	move	#lcd_filtere1,r0	
	jsr	lcd_print_line
	jsr	lcd_4rthline

       	move	#lcd_footer,r0	
	jsr	lcd_print_line
        jsr	delay_2select

	nop
;-----********-----------********---------filter_msj
;-----********-----------********---------filter_msj

	rti
;----------------------------------------------------------------
; The following delay loop is used to make sure that proper
; amount of time is inserted between interrupts caused by
; pressing the switches. This will block the undesired selections
; that may result from the switch.
;----------------------------------------------------------------
delay_2select       
	nop
	do	#3000,wait_2settle   ; 3000 x 10000 x 10.17ns = 305 ms
        move    #10000,x0
        rep     x0                      
        nop
wait_2settle
	rts
