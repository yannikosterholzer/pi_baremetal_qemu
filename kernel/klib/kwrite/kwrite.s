.global kwrite 
.section .data
newline: .byte  0x0d, 0x0a, 0x00

.section .text


@************************************************************************************
@                      kwrite
@ 
@ `kwrite` ist eine Funktion, die Daten an verschiedene Ausgabestellen schreibt, 
@ wie Dateien, die Anzeige oder Fehlerausgaben über UART. 
@ (Wird von kprintf benutzt)
@************************************************************************************
kwrite:         @ input : r0 = OUTPUT-Stream ([0]DISPLAY/[1]File/[2/3]ERROR)
				@         r1 = Adresse des auszugebenden Strings
				@         r2 = Anzahl der auszugebenden Bytes
@ -----------------------------------------------------------------
   	push {lr}
   	push {r11}
   	mov r11, sp
   	and r0, r0, #0x3
   	adr r3, stdout_tbl
   	ldr pc, [r3, r0, lsl #2]
   	b   . //shouln´t be reachable
stdout_tbl:
   Out_0: 
            .word Out_0_handler // Write to Display
   Out_1: 
            .word Out_1_handler // Write to File
   Out_2: 
            .word Out_2_handler // Write to Uart
   Out_3: 
            .word Out_2_handler // Für Table-Alignment

Out_0_handler: @ write to screen
	mov r3, #0
Out_0_loop:
	cmp r3, r2
	bhs Out_0_loop_end
	ldrb r0, [r1, r3]
out_0_check_newline:
	cmp r0, #0x2f
	bne out_0_output
	push {r0}
	add r0, r3, #1
	ldrb r0, [r1, r0]
	cmp r0, #0x6e
	pop {r0}
	bne out_0_output
out_0_newline_output:	
	bl out_0_print_newline
	add r3, r3, #2
	cmp r3, r2
	bhs Out_0_loop_end
	b Out_0_loop
out_0_output:	
	push {r0-r3}
	mov r1, r0
	bl text_printchar
	pop {r0-r3}
	add r3, r3, #1
	b Out_0_loop
Out_0_loop_end:     
	b write_end
	
Out_1_handler: // Write to File
	// ...
    	b       .
	
Out_2_handler: // Error = Uart Output
	mov r3, #0
Out_2_loop:
	cmp r3, r2
	bhs Out_2_loop_end
	ldrb r0, [r1, r3]
out_2_check_newline:
	cmp r0, #0x2f
	bne out_2_output
	push {r0}
	add r0, r3, #1
	ldrb r0, [r1, r0]
	cmp r0, #0x6e
	pop {r0}
	bne out_2_output
out_2_newline_output:	
	bl out_2_print_newline
	add r3, r3, #2
	cmp r3, r2
	bhs Out_2_loop_end
	b Out_2_loop
out_2_output:	
	bl k_uart_write_char 
	add r3, r3, #1
	b Out_2_loop
Out_2_loop_end:     
	b write_end


@************************************************************************************
@                      out_2_print_newline
@ 
@ out_2_print_newline schreibt einen Zeilenumbruch, wenn entsprechende Zeichen erkannt werden ????????
@************************************************************************************	
out_2_print_newline:
	push {lr}
	push {r0-r3}
	mov r0, #2
	ldr r1, =newline
	ldr r2, =2
	bl kwrite
	pop {r0-r3}
	pop {lr}
	bx lr
	
@************************************************************************************
@                      out_0_print_newline
@ 
@ out_0_print_newline schreibt einen Zeilenumbruch am Screen, wenn entsprechende Zeichen erkannt werden 
@************************************************************************************	
out_0_print_newline:
	push {lr}
	push {r0-r3}
	mov r0, #2
	ldr r1, =0xa
	bl text_printchar
	pop {r0-r3}
	pop {lr}
	bx lr


@ return from kwrite
write_end:
	mov sp, r11
	pop {r11}
	pop {lr}
	bx lr
	b .
