	page    132,60
;**************************************************************************
;       ADA_INIT.ASM    Ver 1.1
;       Example program to initialize the CS4218
;
;       Copyright (c) MOTOROLA 1995, 1996, 1998
;		      Semiconductor Products Sector 
;		      Wireless Signal Processing Division
; 
;**************************************************************************
        org     x:
CTRL_WD_HI      ds      1
CTRL_WD_LO      ds      1

                                ; ESSI0 - audio data
                                ; DSP                   CODEC
                                ; ---------------------------
CODEC_RESET     equ     0       ; bit0  SC00    --->    CODEC_RESET~
FSYNC           equ     2       ; bit2  SC02    <---    FSYNC
SCLK            equ     3       ; bit3  SCK0    <---    SCLK
SRD0            equ     4       ; bit4  SRD0    <---    SDOUT
STD0            equ     5       ; bit5  STD0    --->    SDIN

                                ; ESSI1 - control data
                                ; DSP                   CODEC
                                ;----------------------------
CCS             equ     0       ; bit0  SC10    --->    CCS~
CCLK            equ     1       ; bit1  SC11    --->    CCLK
CDIN            equ     2       ; bit2  SC12    --->    CDIN

;**************************************************************************
; Initialize the CS4218 codec
; ---------------------------
; Serial Mode 4 (SM4), DSP Slave/Codec Master, 32-bits per frame
;
; After a reset, the control port must be written once to initialize it
; if the port will be accessed to read or write control bits.  The initial
; write is a "dummy" write since the data is ignored by the codec.  A second
; write is needed to configure the codec as desired.  Then, the control port
; only needs to be written to when a change is desired, or to obtain status
; information.
;
; Although only 23 bits contain useful data in CDIN, a minimum of 31 bits
; must be written.
;
; Please note that the bit numbering is opposite that of the numbering in
; the CS4218 datasheet.
;
; CDIN
;------------------------------------------------       
; bit 31                0
;------------------------------------------------       
; bit 30                mask interrupt
;                       0=no mask on MF5:\INT pin
;                       1=mask on MF5:\INT pin
;------------------------------------------------       
; bit 29                DO1
;------------------------------------------------       
; bits 28-24            left output D/A sttenuation  (1.5dB steps)
;                       00000=No attenuation 0dB
;                       11111=Max attenuation -46.5dB
;------------------------------------------------       
; bits 23-19            right output D/A attenuation (1.5dB steps)
;                       00000=No attenuation 0dB
;                       11111=Max attenuation -46.5dB
;------------------------------------------------       
; bit 18                mute D/A outputs
;                       0=outputs ON
;                       1=outputs MUTED
;------------------------------------------------       
; bit 17                input mux, left select
;                       0=RIN1
;                       1=RIN2 (used on EVM)
;------------------------------------------------       
; bit 16                input mux, right select
;                       0=LIN1
;                       1=LIN2 (used on EVM)
;------------------------------------------------
; bits 15-12            left input A/D gain (1.5dB steps)
;                       0000=No gain 0dB
;                       1111=Max gain +22.5dB
;------------------------------------------------       
; bits 11-8             right input A/D gain (1.5dB steps)
;                       0000=No gain 0dB
;                       1111=Max gain +22.5dB
;------------------------------------------------
; bits 7-0              00000000
;------------------------------------------------
;**************************************************************************

        org     p:
ada_init
        movep   #$0000,x:M_PCRC         ; disable ESSI0 port (for now)
        movep   #$101807,x:M_CRA0       ; 12.288MHz/16 = 768KHz SCLK
                                        ; prescale modulus = 8
                                        ; frame rate divider = 2
                                        ; 16-bits per word
                                        ; 32-bits per frame
                                        ; 16-bit data aligned to bit 23

        movep   #$ff330c,x:M_CRB0       ; Enable REIE,TEIE,RLIE,TLIE,
                                        ; RIE,TIE,RE,TE0
                                        ; network mode, synchronous,
                                        ; out on rising/in on falling
                                        ; shift MSB first
                                        ; external clock source drives SCK 
                                        ; (codec is master)
                                        ; RX frame sync pulses active for
                                        ; 1 bit clock immediately before
                                        ; transfer period
                                        ; positive frame sync polarity
                                        ; frame sync length is 1-bit           
                                        
        movep   #$0001,x:M_PRRC         ; set PC0=CODEC_RESET~ as output
        movep   #$0007,x:M_PRRD         ; set PD0=CCS~ as output
                                        ; set PD1=CCLK as output
                                        ; set PD2=CDIN as output

        bclr    #CODEC_RESET,x:M_PDRC   ; assert CODEC_RESET~
        bclr    #CCS,x:M_PDRD           ; assert CCS~

;Reset delay for codec
        do      #1000,_delay_loop
        rep     #1000                   ; minimum 50 ms delay 
        nop
_delay_loop

;Send control data to codec
        bset    #CODEC_RESET,x:M_PDRC   ; deassert CODEC_RESET~
        movep   #$000c,x:M_IPRP         ; set int priority level for ESSI0 to 3
        andi    #$fc,mr                 ; enable interrupts

dummy_control
        move    #0,x0
        move    x0,x:CTRL_WD_HI         ; send dummy control data
        move    x0,x:CTRL_WD_LO
        jsr     init_codec

set_control                             ; write the symbols CTRL_WD_12 and 
                                        ; CTRL_WD_34 to the memory locations
                                        ; CTRL_WD_HI and CTRL_WD_LO.  The 
                                        ; symbols should be defined in the
                                        ; code to set up the coded as desired
        move    #CTRL_WD_12,x0
        move    x0,x:CTRL_WD_HI         ; LIN2 and RIN2 are inputs

        move    #CTRL_WD_34,x0
        move    x0,x:CTRL_WD_LO         ; 16 bit data aligned to bit 23
        jsr     init_codec

        movep   #$003e,x:M_PCRC         ; enable ESSI0 except SC00=CODEC_RESET
        movep   #$101807,x:M_CRA0       ; 12.288MHz/16 = 768kHz SCLK,
                                        ; 16 bits per word, 2 words per frame
        movep   #$ff330C,x:M_CRB0       ; Enable REIE,TEIE,RLIE,TLIE,
                                        ; RIE,TIE,RE,TE0
                                        ; network mode, synchronous,
                                        ; out on rising/in on falling,
                                        ; shift MSB first,
                                        ; external clock source drives SCK 
        rts

;**************************************************************************
; Initialization routine
;**************************************************************************
init_codec
        clr     a
        bclr    #CCS,x:M_PDRD           ; assert CCS 
        move    x:CTRL_WD_HI,a1         ; upper 16 bits of control data
        jsr     bit_bang 		; shift out upper control word
        move    x:CTRL_WD_LO,a1         ; lower 16 bits of control data
        jsr     bit_bang		; shift out lower control word
        bset    #CCS,x:M_PDRD           ; deassert CCS
        rts

;**************************************************************************
; Bit-banging routine
;**************************************************************************
bit_bang
        do      #16,end_bit_bang        ; 16 bits per word
        bset    #CCLK,x:M_PDRD          ; toggle CCLK clock high
        jclr    #23,a1,bit_low          ; test msb
        bset    #CDIN,x:M_PDRD          ; CDIN bit is high
        jmp     continue
bit_low
        bclr    #CDIN,x:M_PDRD		; CDIN bit is low
continue
        rep     #2                      ; delay
        nop
        bclr    #CCLK,x:M_PDRD          ; toggle CCLK clock low
        lsl     a                       ; shift control word to 1 bit to left
end_bit_bang
        rts

;****************************************************************************
;	SSI0_ISR.ASM    Ver.2.0
;	Example program to handle interrupts through
;       the 56307 SSI0 to move audio through the CS4218
;
;       Copyright (c) MOTOROLA 1998
;		      Semiconductor Products Sector 
;		      Digital Signal Processing Division
;
;******************************************************************************
;************************ SSI TRANSMIT ISR *********************************
ssi_txe_isr
        bclr    #4,x:M_SSISR0           ; Read SSISR to clear exception flag
                                        ; explicitly clears underrun flag
ssi_tx_isr
        move    r0,x:(r6)+              ; Save r0 to the stack.
        move    m0,x:(r6)+              ; Save m0 to the stack.
        move    #1,m0                   ; Modulus 2 buffer.
        move    x:TX_PTR,r0             ; Load the pointer to the tx buffer.
        movep   x:(r0)+,x:M_TX00        ; SSI transfer data register.
        move    r0,x:TX_PTR             ; Update tx buffer pointer.
        move    x:-(r6),m0              ; Restore m0.
        move    x:-(r6),r0              ; Restore r0.
        rti

;********************* SSI TRANSMIT LAST SLOT ISR **************************
ssi_txls_isr
        move    r0,x:(r6)+              ; Save r0 to the stack.
        move    #TX_BUFF_BASE,r0        ; Reset pointer.
        move    r0,x:TX_PTR             ; Reset tx buffer pointer just in 
                                        ; case it was corrupted.
        move    x:-(r6),r0              ; Restore r0.
        rti

;************************** SSI receive ISR ********************************
ssi_rxe_isr
        bclr    #5,x:M_SSISR0           ; Read SSISR to clear exception flag
                                        ; explicitly clears overrun flag
ssi_rx_isr
        move    r0,x:(r6)+              ; Save r0 to the stack.
        move    m0,x:(r6)+              ; Save m0 to the stack.
        move    #1,m0                   ; Modulus 2 buffer.
        move    x:RX_PTR,r0             ; Load the pointer to the rx buffer.
        movep   x:M_RX0,x:(r0)+         ; Read out received data to buffer.
        move    r0,x:RX_PTR             ; Update rx buffer pointer.
        move    x:-(r6),m0              ; Restore m0.
        move    x:-(r6),r0              ; Restore r0.
        rti

;********************** SSI receive last slot ISR **************************
ssi_rxls_isr
        move    r0,x:(r6)+              ; Save r0 to the stack.
        move    #RX_BUFF_BASE,r0        ; Reset rx buffer pointer just in 
                                        ; case it was corrupted.
        move    r0,x:RX_PTR             ; Update rx buffer pointer.
        move	x:-(r6),r0              ; Restore r0.
        rti
