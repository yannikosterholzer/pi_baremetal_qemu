.equ GPIO,		        0x3F200000      @ GPIO_Base Register		 
.equ UART0,		GPIO  + 0x00001000	@ Baseaddress
.equ UART0_DR, 		UART0 + 0x00000000  	@ Data Register
.equ UART0_FR, 		UART0 + 0x00000018	@ Flag Register
.equ UART0_IBRD,        UART0 + 0x00000024      @ Integer Baud Rate Divisor
.equ UART0_FBRD,	UART0 + 0x00000028      @ Fractional Baud Rate Divisor
.equ UART0_LCRH,	UART0 + 0x0000002C      @ Line Control Register
.equ UART0_CR, 		UART0 + 0x00000030      @ Control Register
.equ UART0_IMSC,        UART0 + 0x00000038      @ Interrupt Mask Set Clear Register

.global k_uart0_init
.global k_uart_write_char
.global k_uart_read_char
.section .text

@************************************************************************************
@                      k_uart0_init
@
@ Die Funktion k_uart0_init initialisiert die UART0-Schnittstelle. 
@ Sie setzt die Steuerung zurück, konfiguriert die Baudrate und aktiviert FIFOs. 
@ Schließlich wird die UART-Schnittstelle aktiviert.
@************************************************************************************
        k_uart0_init:		
	uart_ctrl_reset:  							    @ Reset CTRL Reg   
				push	{r0-r1,lr}
				mov	r0, #0
				ldr     r1, =UART0_CR
				str	r0, [r1]
					
			
	setbaudrate:                                                                @ Setze Integer Baud Rate Divisor auf 26 
				mov	r0, #26        
				ldr 	r1, =UART0_IBRD
				str	r0, [r1]
				
				mov	r0, #0			                    @ Setze Fractional Baudrate Divisor zu 0 
				ldr 	r1, =UART0_FBRD
				str	r0, [r1]
	enable_t_s:								    @ enabdle FIFOs & set Word length to 8 bit
				mov 	r0, #7
				lsl	r0, r0, #4
				ldr 	r1, =UART0_LCRH
				str	r0, [r1]
	disable_int:	
				mov	r0, #0     			            @ 0 fuer polling  8 fuer interrupt
				ldr 	r1, =UART0_IMSC
				str	r0, [r1]			
	uart_enable:	
				ldr   	r0, =0x301
				ldr 	r1, =UART0_CR
				str	r0, [r1]
				pop	{r0-r1,lr}
				bx 	lr
				b 	.
			
@************************************************************************************
@                      k_uart_write_char
@
@ Die Funktion k_uart_write_char sendet ein einzelnes Byte 
@ über die UART0-Schnittstelle, nachdem sie überprüft hat, 
@ ob der Übertragungspuffer leer ist.
@************************************************************************************

	k_uart_write_char:                                                          @ byte fuer ausgabe wird in r0 uebergeben																
				push	{r1-r3}
				mov 	r2, #0x20
				ldr 	r1, =UART0_FR											
	uart_wr_checkfr:							    @ check bit #5 im Flag Register 
				ldr	r3, [r1]
				tst	r2, r3
				bne	uart_wr_checkfr
	uart_wr_print:
				ldr 	r1, =UART0_DR
				strb 	r0, [r1]
				pop	{r1-r3}
				bx 	lr
				b 	.
				
@************************************************************************************
@                      k_uart_read_char
@ 
@ Die Funktion k_uart_read_char liest ein einzelnes Byte von der UART0-Schnittstelle. 
@ Sie überprüft zuerst, ob das Empfangspuffer-Register (RX-FIFO) leer ist, 
@ und gibt dann das gelesene Byte zurück.
@************************************************************************************			
	k_uart_read_char:
				mov 	r2, #0x10
				ldr 	r1, =UART0_FR
	uart_rd_checkfr:							      @ check bit #4 Flag Register
				ldr	r3, [r1]
				tst	r2, r3
				bne	uart_rd_checkfr
	uart_rd_ret:
				ldr r1, =UART0_DR
				ldrb r0, [r1]					      @ gelesenes Byte in r0
				bx 	lr
				b 	.
			
			

			
