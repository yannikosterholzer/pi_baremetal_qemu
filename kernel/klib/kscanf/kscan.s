.global kscan
.extern kprintf
.extern memset
.extern kread


.equ BASE,		   		        0x00
.equ STR_ADR,           BASE -  0x04  
.equ PARAM_CNT,         BASE -  0x08  
.equ STACKMAX,          BASE -  PARAM_CNT
// --------------------------------------
.equ ARGS,              BASE +  0x04     @ offset noetig, da r11 + 4 nicht erstes Argument, sondern Rücksprungadr wäre
// --------------------------------------
.section .data
  unknown_for_str:    .asciz "Error: unknown format identifier" 
  .equ un_for_length,       ( scan_error_str - unknown_for_str)
  
  scan_error_str:        .asciz "Error: scanf - no args" 
  scerror_end:          
  .equ sc_er_length,           ( scerror_end - scan_error_str)
  
  dez_error1_str:        .asciz "Error: %d no input"
  dezerror1_end: 
  .equ dez_er1_length,         ( dezerror1_end - dez_error1_str)  
  
  error_input_str:       .asciz "Error: unexpected input"
  inputerror_end: 
  .equ input_er_length,        ( inputerror_end - error_input_str) 
  
  str_error_str:         .asciz "Error: %s no input"
  strerror_end: 
  .equ str_er_length,          ( strerror_end - str_error_str) 
  
  error_wrinput_str:     .asciz "Error: %s input"
  wrinerror_end: 
  .equ wrinputstr_er_length,       ( wrinerror_end - error_wrinput_str) 

 

 
 .balign 4
 
 

  kscanf_buffer:
                       .space 1024, 0x0

.section .text
kscan: // r1 = formatstring
	push {lr}
	push {r11}
	mov r11, sp
	sub sp, sp, #STACKMAX
	str r1, [r11, #STR_ADR]
	mov r2, #0
	str r2, [r11, #PARAM_CNT]
    	push {r6} 
	
scan_srcstr_loop:
	ldr  r0, [r11, #STR_ADR]
	ldrb r1, [r0], #1
	str  r0, [r11, #STR_ADR]
	cmp  r1, #0
	beq  scanf_end_scan
	cmp  r1, #'%'   @ Umwandlungszeichen?
	beq  format_id
	b  scan_srcstr_loop
format_id:
	ldr	r1, [r11, #PARAM_CNT]    @ aktueller param index in r2
	add	r1, r1, #4 
	str     r1, [r11, #PARAM_CNT]   
	ldr     r0, [r11, #STR_ADR]
	ldrb    r1, [r0]
	add     r0, r0, #1
	str     r0, [r11, #STR_ADR]
	cmp     r1, #126                 @ 127 == DEL
	bhi     checkerror
	cmp     r1, #65                  @ 65 -> 126 = Buchstaben
	bhi     checkasc				 @ wenn falsch -> faellt kontrolle automatisch in checkerror
checkerror:
	mov     r0, #2
	ldr     r1, =unknown_for_str
	ldr     r2, =un_for_length
	bl 	kwrite
	ldr	r0, =0xffffffff //Error!
	b       scanf_end	
scanf_end_scan:
	ldr r1, [r11, #PARAM_CNT]
	cmp r1, #0     @ wenn scanf zuende & parametercounter == 0 muss fehler vorliegen!
	bne scanf_end
scan_error:
	mov     r0, #2
	ldr     r1, =scan_error_str
	ldr     r2, =sc_er_length
	bl 	kwrite
	ldr	r0, =0xffffffff //Error!
scanf_end:
	pop {r6} 
	mov sp, r11
	pop {r11}
	pop {lr}
	bx lr



checkasc:
	orr 	r1, #32
	sub 	r1, r1, #0x61
	adr	r0, ascii_jmp_tbl
	ldr 	pc, [r0, r1, lsl #2]
	b	.                    //shouln´t be reachable

.balign 4	
ascii_jmp_tbl:
    a: .word checkerror
    b: .word checkerror
    c: .word checkerror
    d: .word sc_is_d
    e: .word checkerror
    f: .word checkerror
    g: .word checkerror
    h: .word checkerror
    i: .word sc_is_d
    j: .word checkerror
    k: .word checkerror
    l: .word checkerror
    m: .word checkerror
    n: .word checkerror
    o: .word checkerror
    p: .word checkerror
    q: .word checkerror
    r: .word checkerror
    s: .word sc_is_s
    t: .word checkerror
    u: .word checkerror
    v: .word checkerror
    w: .word checkerror
    x: .word sc_is_x
    y: .word checkerror
    z: .word checkerror
.balign 4



	
sc_is_d:         
	ldr r1, =kscanf_buffer
	mov r2, #0
	mov r3, #10
	bl memset                    @ clear buffer

sc_get_val:
	mov r0, #1
	ldr r1, =kscanf_buffer
	mov r2, #11
	bl kread
	ldr r1, =0xffffffff
	cmp r0, r1
	beq error_dez
	cmp r0, #10
	beq error_dez
	mov r3, r0
	mov r2, #0
	ldr r1, =kscanf_buffer
sc_dez_check_minus:
	ldrb r0, [r1, r2]
	cmp r0, #0x2d
        moveq r6, #1
	movne r6, #0
	addeq r2, r2, #1
sc_dez_check_buff_all:
	ldrb r0, [r1, r2]              @ lade Byte von Buffer zwecks überprüfung ob Ziffer
	cmp r0, #0x30                  @ value < Ascii "0" ?
	blo error_wrong_input
	cmp r0, #0x39                  @ value > Ascii "9"?
	bhi error_wrong_input
	cmp r2, r3
	beq dez_buff_process
	add r2, r2, #1
	b sc_dez_check_buff_all
dez_buff_process:	
	mov r0, #0
	mov r2, #1
	push {r4,r5}			 
	add r5, r3, #1
   	mov r3, #0
	mov r4, #10
	add r3, r6, #0
dez2reg_loop:
	ldr r1, =kscanf_buffer
	ldrb r1, [r1, r3]
	sub r1, r1, #0x30    //ASCI -> Value         
dez_arithm:	
	mov r2, #10
	mla r0, r0, r2, r1   // r0 = (r0 * 10 ^ x ) + r1
	add r3, r3, #1
	cmp r3, r5
	bne dez2reg_loop	 
dez_end:
	pop {r4,r5}
	mov  r1, #0
	cmp  r6, r1
	subne  r0, r1, r0             @resultat ist negativ (zweierkomplement)  			
	ldr r1, [r11, #PARAM_CNT] 
	add r1, #ARGS
	str r0, [r11, r1]
        b format_id_end
sc_is_s:
	ldr r1, =kscanf_buffer
	mov r2, #0
	ldr r3, =#1024
	bl memset                    @ clear buffer	
get_string:	
	mov r0, #1
	ldr r1, =kscanf_buffer
	mov r2, #1024
	bl kread
	ldr r1, =0xffffffff
	cmp r0, r1
	beq error_s
	mov r3, r0
	mov r2, #0		 			
check_strbuff_prep:
	mov r2, #0
	ldr r6, =kscanf_buffer
	ldr r1, [r11, #PARAM_CNT] 
	add r1, #ARGS
	ldr r1, [r11, r1]
			           @ speichere das Ergebnis über pointer im Ziel      
check_strbuff_loop:
	ldrb r0, [r6], #1          @ postincrement
	cmp r0, #0x20              @ 0x20 = Leerzeichen, niedrigere Werte sind andere Steuerzeichen
	blo error_wrong_input_str
	strb r0, [r1, r2] 
	cmp r3, r2			 
	beq str_proc_end
	add r2, r2, #1
	b check_strbuff_loop
str_proc_end:
	b format_id_end
sc_is_x:
	b .                           @ (noch) nicht implementiert
			 	      @ is_x -> falle durch zu format_id_end
format_id_end:
	b  scan_srcstr_loop


error_dez:
	mov     r0, #2
	ldr     r1, =dez_error1_str
	ldr     r2, =dez_er1_length
	bl 	kwrite
	ldr	r0, =0xffffffff
	b       scanf_end
error_wrong_input:
	mov     r0, #2
	ldr     r1, =error_input_str
	ldr     r2, =input_er_length
	bl 	kwrite
	ldr	r0, =0xffffffff
	b       scanf_end
error_s:
	mov     r0, #2
	ldr     r1, =str_error_str
	ldr     r2, =str_er_length
	bl 	kwrite
	ldr	r0, =0xffffffff
	b       scanf_end
error_wrong_input_str:
	mov     r0, #2
	ldr     r1, =error_wrinput_str
	ldr     r2, =wrinputstr_er_length
	bl 	kwrite
	ldr	r0, =0xffffffff
	b       scanf_end


