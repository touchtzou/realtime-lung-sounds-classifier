        page    132,60
;****************************************************************************
;   VECTORS.ASM
;   Vector table for the 56311                                        
;
;   Copyright (c) MOTOROLA 1998
;            Semiconductor Products Sector 
;            Digital Signal Processing Division
;
;****************************************************************************
;
         ORG       P:0

vectors  jmp       START            ;- Hardware RESET                  

         jmp       *    
         NOP                        ;- Stack Error

         jmp       *    
         NOP                        ;- Debug Request Interrupt     

         jmp       *    
         NOP                        ;- Debug Request Interrupt     

         jmp       *    
         NOP                        ;- Trap                        

         jmp       *    
         NOP                        ;- NMI                         

         NOP                        ;- Reserved                    
         NOP

         NOP                        ;- Reserved                    
         NOP

         jmp       *    
         NOP                        ;- IRQA                            

         jmp       *    
         NOP                        ;- IRQB                            

         jmp       *    
         NOP                        ;- IRQC                        

         jmp       *
         NOP                        ;- IRQD

         jmp       *    
         NOP                        ;- DMA Channel 0               

         jmp       *    
         NOP                        ;- DMA Channel 1                

         jmp       *    
         NOP                        ;- DMA Channel 2                

         jmp       *    
         NOP                        ;- DMA Channel 3                

         jmp       *    
         NOP                        ;- DMA Channel 4                

         jmp       *    
         NOP                        ;- DMA Channel 5                

         jmp       *    
         NOP                        ;- Timer 0 Compare             

         jmp       *    
         NOP                        ;- Timer 0 Overflow            

         jmp       *    
         NOP                        ;- Timer 1 Compare             

         jmp       *    
         NOP                        ;- Timer 1 Overflow            

         jmp       *    
         NOP                        ;- Timer 2 Compare             
 
         jmp       *    
         NOP                        ;- Timer 2 Overflow            

         jsr       ssi_rx_isr       ;- ESSI0 Receive Data          

         jsr       ssi_rxe_isr      ;- ESSI0 Receive Data w/ Exception Status  
        
         jsr       ssi_rxls_isr     ;- ESSI0 Receive Last Slot     

         jsr       ssi_tx_isr       ;- ESSI0 Transmit Data         

         jsr       ssi_txe_isr      ;- ESSI0 Transmit Data w/ Exception Status 
        
         jsr       ssi_txls_isr     ;- ESSI0 Transmit Last Slot     

         NOP                        ;- Reserved                    
         NOP
         
         NOP                        ;- Reserved                      
         NOP

         jmp       *    
         NOP                        ;- ESSI1 Receive Data          

         jmp       *    
         NOP                        ;- ESSI1 Receive Data w/ Exception Status  

         jmp       *    
         NOP                        ;- ESSI1 Receive Last Slot     

         jmp       *    
         NOP                        ;- ESSI1 Transmit Data         

         jmp       *    
         NOP                        ;- ESSI1 Transmit Data w/ Exception Status 

         jmp       *    
         NOP                        ;- ESSI1 Transmit Last Slot    
         
         NOP                        ;- Reserved                    
         NOP
          
         NOP                        ;- Reserved                    
         NOP
 
         jmp       *    
         NOP                        ;- SCI Receive Data            

         jmp       *    
         NOP                        ;- SCI Receive Data w/ Exception Status 
 
         jmp       *    
         NOP                        ;- SCI Transmit Data           

         jmp       *    
         NOP                        ;- SCI Idle Line               
        
         jmp       *    
         NOP                        ;- SCI Timer                   

         NOP                        ;- Reserved                    
         NOP
          
         NOP                        ;- Reserved                    
         NOP

         NOP                        ;- Reserved                    
         NOP
         
         jmp       *    
         NOP                        ;- Host Receive Data Full  

         jmp       *    
         NOP                        ;- Host Transmit Data Empty 
        
         jmp       *    
         NOP                        ;- Host Command (Default)     

         NOP                        ;- Reserved                    
         NOP

         jmp       *    
         NOP                        ;- EFCOP Data Input Buffer Empty   

         jmp       *    
         NOP                        ;- EFCOP Data Output Buffer Full   

         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
         jmp       *    
         NOP                        ; Available for Host Command      
