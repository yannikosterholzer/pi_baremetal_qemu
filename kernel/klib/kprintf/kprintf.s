.global kprintf       
.extern kwrite
.extern memset
.extern k_uart_write_char
.extern num_2_dec
.extern num2hexascii
.extern str_get_length

.section .data
  kprintf_buffer:      .space 1024, 0x0
  Hex_Lookup:	       .asciz "0123456789ABCDEF"
                       .balign 4
  HexAusgabe:	       .ascii "0x"
                       .balign 1
  HexString:           .byte  0,0,0,0,0,0,0,0
  format_id_error_str: .asciz "Umwandlung übersteigt Buffergroesse /n"
  check_error_str:     .asciz "Illegales Umwandlungszeichen /n"
  error_end:           .byte  0x00

@ equs  
.equ fid_length,       ( check_error_str - format_id_error_str)
.equ cer_length,       ( error_end - check_error_str)	
                       .balign 4
	 
.section .text
.equ BASE,		   	0x00
.equ ARGS,              BASE +  0x04 @ offset noetig, da r11 + 4 nicht erstes Argument, sondern Rücksprungadr wäre

.equ STR_ADR,           BASE -  0x04 
.equ OUT_TYPE,	        BASE -  0x08 
.equ BUFF_CNT,	   		BASE -  0x0C		
.equ PARAM_CNT,         BASE -  0x10  
.equ FIELD_W,           BASE -  0x14   
.equ STACKMAX,          BASE -  FIELD_W 



@************************************************************************************
@                      kprintf
@ 
@ `kprintf` ist eine Funktion zur Formatierung und Ausgabe von Zeichenfolgen auf der Konsole. 
@ Sie verwendet eine ähnliche Syntax wie `printf` in C und unterstützt verschiedene Formatierungsoptionen wie 
@ `%d` für Dezimalzahlen, 
@ `%u` für vorzeichenlose Dezimalzahlen, 
@ `%s` für Zeichenfolgen und `%x` für hexadezimale Zahlen. 
@ Die Funktion extrahiert die formatierten Daten aus dem Eingabeformatstring, 
@ wandelt gegebenenfalls Argumente um und speichert sie in einem Puffer. 
@ Schließlich gibt sie den Inhalt des Puffers aus.
@************************************************************************************
kprintf:    	@ input : r1 = Adresse des nullterminierten Format-Strings (z.B: "lorem ipsum doloret.. %s ..%f../n")
		@         r2 = output-type (0=DISPLAY[Textmode]/1=File/2=ERROR/3=Error) 
		@         Parameter werden über Stack übergeben: Die zuerst benutzten Argumente müssen zuletzt gepusht werden
@ -----------------------------------------------------------------  
	push {lr}                   
	push {r11}
	mov r11, sp
	sub sp,	sp, #STACKMAX	    
	str r1, [r11, #STR_ADR  ]
	str r2, [r11, #OUT_TYPE ]
	mov r0, #0
	str r0, [r11, #BUFF_CNT ]
	str r0, [r11, #PARAM_CNT]
	str r0, [r11, #FIELD_W  ]   @ für formattierte ausgabe
	push {r4, r5, r6, r7}

clear_buff:
	ldr r0, =kprintf_buffer     @ clear Buffer 
	mov r1, #0x00
	mov r2, #1024
	bl memset	
	
scan_srcstr_loop:				
	ldr r0, [r11, #STR_ADR]
	ldrb r1, [r0]   
	cmp r1, #0                   @ Ende des nullterminierten Strings erreicht?
	beq kprintf_buf_out
	cmp r1, #0xD                 @ Enter?
	beq kprintf_buf_out
	cmp r1, #'%'                 @ Umwandlungszeichen?
	bne buff_str_char
	ldr r1, [r11, #PARAM_CNT]   
	add r1, r1, #4                      
	str r1, [r11, #PARAM_CNT]    
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR]
	ldrb r1, [r1]                 @ Lade das nächste Zeichen nach %
		
format_id:                           
check: 
	mov r3, #1
check_loop:                          @ prüfe ob zeichen nach % eine nummer d.h Fieldwith
	cmp r1, #64
	bhi checkasc
	cmp r1, #0x30
	blo checkerror
	cmp r1, #0x40
	bhs checkerror
	push {r2}
	ldr r2, [r11, #FIELD_W]
	sub r1, r1, #0x30
	mov r0, #10
	push {r5}
	umull r2, r5, r2, r3           @ fieldwith
	umull r3, r5, r3, r0    
	pop {r5}
	add r1, r1, r2
	str r1, [r11, #FIELD_W]
	pop {r2}
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldrb r1, [r1]
	b check_loop
checkasc:
	orr r1, #32
	cmp r1, #0x7b
	bhs checkerror
	sub r1, r1, #0x61
	adr r0, ascii_jmp_tbl
	ldr pc, [r0, r1, lsl #2]
	b  .                        

.balign 4	
ascii_jmp_tbl:
    a: .word checkerror
    b: .word checkerror
    c: .word checkerror
    d: .word is_d
    e: .word checkerror
    f: .word is_f
    g: .word checkerror
    h: .word checkerror
    i: .word is_d
    j: .word checkerror
    k: .word checkerror
    l: .word checkerror
    m: .word checkerror
    n: .word checkerror
    o: .word checkerror
    p: .word checkerror
    q: .word checkerror
    r: .word checkerror
    s: .word is_s
    t: .word checkerror
    u: .word is_u
    v: .word checkerror
    w: .word checkerror
    x: .word is_x
    y: .word checkerror
    z: .word checkerror
.balign 4	
checkerror:
    	mov r0, #2
	ldr r1, =check_error_str
	ldr r2, =cer_length
	bl kwrite
	b  kprintf_end
@----------------------------------------
is_f:
	ldr r2, [r11, #BUFF_CNT]
	mov r0, #1024
	add r3, r2, #10
	cmp r3, r0
	bhs format_id_error	
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldr r1, [r11, #PARAM_CNT]
	add r1, #ARGS
	ldr r1, [r11, r1]
float_conv:
	bl float2ascii
	mov r4, r1
	b print_to_buff
@----------------------------------------
is_u:
	ldr r2, [r11, #BUFF_CNT]
	mov r0, #1024
	add r3, r2, #10
	cmp r3, r0
	bhs format_id_error	
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldr r1, [r11, #PARAM_CNT] 
	add r1, #ARGS
	ldr r1, [r11, r1]
	mov r2, #0
	b conv_dec_asc
@----------------------------------------	
is_d:
	ldr r2, [r11, #BUFF_CNT]
	mov r0, #1024
	add r3, r2, #10
	cmp r3, r0
	bhs format_id_error	
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldr r1, [r11, #PARAM_CNT] 
	add r1, #ARGS
	ldr r1, [r11, r1]
check_minus:		
	mov r0, #0
	ldr r2, =#0x80000000
	and r3, r1, r2
	cmp r3, #0
	moveq r2, #0
	beq conv_dec_asc
	mov r2, #1
	sub r1, r2, r1
	mov r1, #1
conv_dec_asc:
	bl num_2_dec
	mov r4, r1
	b print_to_buff
@----------------------------------------
is_s:
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldr r1, [r11, #PARAM_CNT]
	add r1, #ARGS
	ldr r1, [r11, r1]
is_s_get:
	bl  str_get_length
	mov r4, r1
	b print_to_buff
@----------------------------------------
is_x:
	ldr r2, [r11, #BUFF_CNT]
	mov r0, #1024
	add r3, r2, #10
	cmp r3, r0
	bhs format_id_error	
	ldr r0, [r11, #STR_ADR]
	add r1, r0, #1
	str r1, [r11, #STR_ADR] 
	ldr r1, [r11, #PARAM_CNT]
	add r1, #ARGS
	ldr r1, [r11, r1]
is_x_convert:
	bl num2hexascii
	mov r4, r1
@----------------------------------------
print_to_buff:
	push {r0}
	ldr r2, [r11, #BUFF_CNT]
	mov r0, #1024
	add r3, r2, r1        @ r3 = stringlength + buffercount     
	cmp r3, r0   
	pop {r0}
	bhs format_id_error	
	push {r4}
	ldr r4, =kprintf_buffer
print:
	push {r0-r3}
	add r5, r4, r2
	add r2, r1, #1
	mov r1, r0
	mov r0, r5
	bl memcpy 
	pop {r0-r3}
print_end:
	pop {r1}	
	add r1, r1, #1
	add r2, r2, r1
	ldr r5, [r11, #FIELD_W]
	subs r5, r5, r1
	movle r3, #0
	strle r3, [r11, #FIELD_W]
	ldr r0, =kprintf_buffer
print_fill:	
	ble print_is_filled
	mov r1, #0x20
	strb r1, [r0, r2]
	add r2, r2, #1
	subs r5, r5, #1
	b  print_fill
print_is_filled:	     
	str r2, [r11, #BUFF_CNT]
	ldr r2, [r11, #FIELD_W]
	mov r2, #0
	str r2, [r11, #FIELD_W]
format_id_end:	
	b  scan_srcstr_loop
@----------------------------------------		
buff_str_char:
	ldr r3, =kprintf_buffer
	ldr r2, [r11, #BUFF_CNT] 
	ldr r0, [r11, #STR_ADR ] 
	ldrb r1, [r0]              @ lade byte aus string
	strb r1, [r3, r2]          @ speicher in buffer
	add r2, r2, #1            @ erhöhe BUFF_CNT
	str r2, [r11, #BUFF_CNT]  @ bufferposition anpassen
	ldr r0, [r11, #STR_ADR ]  @ erhöhe stringaddresse
	add r0, r0, #1
	str r0, [r11, #STR_ADR ]
	b scan_srcstr_loop
@----------------------------------------
format_id_error:
	mov r0, #2
	ldr r1, =format_id_error_str
	ldr r2, =fid_length
	bl kwrite
	b  kprintf_end
@----------------------------------------	
kprintf_buf_out:
	ldr r0, [r11, #OUT_TYPE]
	ldr r1, =kprintf_buffer
	ldr r2, [r11, #BUFF_CNT]
	bl kwrite
@----------------------------------------	
kprintf_end:
	pop {r4, r5, r6, r7}
    	add sp, sp, #STACKMAX
	mov sp, r11
	pop {r11}
	pop {lr}
	bx lr
	b   .
		


	
	
	
	
