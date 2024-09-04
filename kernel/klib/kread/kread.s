.global kread
.extern k_uart_read_char
.extern k_uart_write_char 

.section .data 

  newline:    .asciz "/n" 
.section .text


@************************************************************************************
@                      kread
@ 
@ `kread` ist eine Funktion, die Daten von verschiedenen Eingabestellen einliest, 
@  etwa von UART oder Dateien
@ (Wird von kscanf benutzt)
@************************************************************************************
kread:             // r0 = INPUT-Stream (FILE/UART) //r1 = destination address (von kscanf gestellt) //r2 = Number of Bytes to read (von kscanf gestellt) // r3 = sourcedata (?) Das zu implementieren setzt filesystem voraus und umschreiben des codes da r3 anderweitig benutzt wird
   	push 	{lr}
   	push 	{r11}
   	mov 	r11, sp
  	and  r0, r0, #0x1
   	adr	r3, input_tbl
  	ldr 	pc, [r3, r0, lsl #2]
   	b   . //shouln´t be reachable
input_tbl:
   in_0: 
            .word in_0_handler // read from File
   in_1: 
            .word in_1_handler // read from uart
   	b        .
   
in_0_handler: // read from File
	 b        .
in_1_handler: // read from uart
	sub     r2, r2, #1
	mov     r3, #0 //count
scan_loop:
	push 	{r1,r2,r3}
	bl 	k_uart_read_char
	pop 	{r1,r2,r3}
	cmp     r0, #0xD // CR?
	bne	scan_not_enter
scan_enter: 
	mov     r0, #2
	ldr     r1, =newline
	mov     r2, #2
	push    {r3}
	bl 	kwrite
	pop     {r3}
	cmp	r3, #0
	movne	r0, #0
	bne	scan_end_correct
	b	scanstr_error
	
scan_not_enter:
	cmp	r0, #0x8
	beq 	read_del
	cmp	r0, #0x20 
	blo	scan_loop
//	beq     skip_save  // unnecessary
ami_ger_tastatur:
	cmp     r0, #0x59    @ Y -> Z
	addeq   r0, r0, #1 
	beq     ami_ger_skip
	cmp     r0, #0x5a    @ Z -> Y
	subeq   r0, r0, #1
	beq     ami_ger_skip
	cmp     r0, #0x79    @ Y -> Z
	addeq   r0, r0, #1
	beq     ami_ger_skip
	cmp     r0, #0x7a    @ z -> y
	subeq   r0, r0, #1
ami_ger_skip:
	bl 	k_uart_write_char 
	strb	r0, [r1, r3]
	cmp	r3, r2
	add	r3, r3, #1
	bne	scan_loop

	
scanstr_error:
	ldr	r0, =0xffffffff
	b       scan_end
scan_end_correct:
	sub     r0, r3, #1    @ stringlänge in r0
scan_end:
	mov     sp, r11
	pop     {r11}
	pop 	{lr}
	bx 	lr
	
read_del:
	cmp r3, #0
	beq scan_loop
	bl k_uart_write_char
	sub r3, r3, #1
	b scan_loop

skip_save:
	bl k_uart_write_char 
	b scan_loop
	
