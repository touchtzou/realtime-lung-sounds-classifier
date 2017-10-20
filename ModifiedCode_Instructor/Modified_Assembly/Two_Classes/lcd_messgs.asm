;-----------------------------------------------
; This file contains all the ASCII characters 
; that are going to be displayed on the LCD.
;-----------------------------------------------

lcd_welcome10	dc	'   ** Welcome **@'
lcd_welcome11	dc	' Please, Use "MENU" @'
lcd_welcome12	dc	' Button to Make Your@'
lcd_welcome13	dc	'     Selection@'

lcd_header	dc	'****  < MENU >  ****@'
lcd_footer	dc	'****            ****@'

lcd_record20	dc	' 2) Start Recording@'
lcd_record21	dc	'   the Lung Sound@'

lcd_record30	dc	'**  < RECORDING > **@'
lcd_record31	dc	'* A Total Duration *@'
lcd_record32	dc	'*   of 16 Seconds  *@'

lcd_record40	dc	' * RECORDING ENDED *@'
lcd_record41	dc	'  To Listen to the@'
lcd_record42	dc	'Sound, Please Select@'
lcd_record43	dc	'   LISTEN Option@'

lcd_listen50	dc	'  3) Listen to the@'
lcd_listen51	dc	' Recorded Lung Sound@'

lcd_listen60	dc	'*** < PLAYING >  ***@'
lcd_listen61	dc	'* The Recorded Lung*@'
lcd_listen62	dc	'*      Sound       *@'

lcd_listen70	dc	'*** < FINISHED > ***@'
lcd_listen71	dc	'Playing the Recorded@'
lcd_listen72	dc	'    Lung Sound@'

lcd_knn		dc	' K-nearest neighbor@'
lcd_euclid80	dc	' 4) Classify Using@'
lcd_euclid81	dc	' (Euclidean Measure)@'

lcd_itakur90	dc	' 6) Classify Using@'
lcd_itakur91	dc	' (Itakura Measure)@'

lcd_cityblocka0	dc	' 5) Classify Using@'
lcd_cityblocka1	dc	' (Cityblock Measure)@'

lcd_mahalanobb0 dc	'1) Classify with Min@'
lcd_mahalanobb1	 dc	' Distance Classifier@'
lcd_mahalanobb2 dc	'(Mahalanobis Metric)@'

lcd_breathc0	dc	' Whenever You Feel@'
lcd_breathc1	dc	'Ready, Please Start@'
lcd_breathc2	dc	' Breathing through@' 
lcd_breathc3	dc	'   the Flowmeter@'

lcd_filterd0	dc	'7) Apply a Digital @'
lcd_filterd1	dc	'      Filter@'


lcd_filtere0	dc	'   8) Remove The@'
lcd_filtere1	dc	'  Digital  Filter@'


lcd_end		dc	'  ** TEST ENDED **@'
lcd_diagnose	dc	'The Diagnosis Result@'
lcd_healthy	dc	'    < HEALTHY >@'
lcd_pathology	dc	'  < PATHOLOGICAL >@'

lcd_restart0	dc	' ** RESTARTING **@'
lcd_restart1	dc	' Please Wait while@'
lcd_restart2	dc	'   Preparing for@'
lcd_restart3	dc	'    a New Test@'


lcd_error0	dc	'****   ERROR    ****@'
lcd_error1	dc	'Unresolved Situation@'
lcd_error2	dc	'   Repeat the Test@'
lcd_error3	dc	'**     Please     **@'
lcd_vote_strt	dc	'  **   @'
lcd_vote_end	dc	'/60    **@'