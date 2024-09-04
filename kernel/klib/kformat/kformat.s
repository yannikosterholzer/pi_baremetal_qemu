.global num_2_dec
.global num2hexascii
.global float2ascii
.section .data

 div_10:                .float  0.1 
 sign:                  .byte 0x0
						.balign 4
 num2dec_buffer:
						.space 16, 0x0
	 

 Hex_Lookup:	       .asciz "0123456789ABCDEF"
                       .balign 4
 kformat_buffer:	       
					   .space 120, 0x0
	 				   .balign 4

////////////////////// Es fehlt bei beiden fkt überprüfung von kformat_buffer_ende!  bufferoverflow, man sollte zudem num_2.. so umschreiben, dass es wie auch hex das filling bereits hier erledigt
////////////////////// zudem fehlt überprüfung von negativen werten bei dez!
.section .text

@************************************************************************************
@                      float2ascii
@ 
@ Die Funktion `float2ascii` konvertiert eine gegebene Gleitkommazahl in ihre ASCII-Darstellung
@ und speichert sie in einem internen Puffer. 
@ Der Rückgabewert r0 zeigt auf den Puffer
@ Der Rückgabewert r1 gibt die Länge des erzeugten Strings an.
@ Die Funktion ermöglicht auch die Angabe einer Feldbreite (fieldwidth) für die Ausgabe.
@************************************************************************************
float2ascii: // r1 = input , r3 = fieldwidth returnwert in r0 = ptr auf buffer mit str r1 = length
	push {lr}
	push {r11}
	mov  r11, sp
	vmov s0, r1
	push {r3}
float_asc:	
	vcvt.s32.f32 s1, s0
	vmov r0, s1
	cmp r0, #0
	bge float_positive
float_negative:
	ldr r1, =#-1
	vmov s2, r1
	vcvt.f32.s32 s2, s2
	vcvt.f32.s32 s1, s1
	vmul.f32 s1, s1, s2
	vmul.f32 s0, s0, s2
	vsub.f32 s0, s0, s1
	mov r1, #0
	sub r1, r1, r0
	mov r2, #1
	mov r3, #0
	bl num_2_dec
	b fraction
float_positive:
	vcvt.f32.s32 s1, s1
	vsub.f32 s0, s0, s1
	mov r1, r0
	mov r2, #0
	mov r3, #0
	bl num_2_dec
fraction:
	pop  {r3}
	add r1, r1, #1
	mov r2, #0x2e
	strb r2, [r0, r1]
	add r1, r1, #1
	// push {r1}
	mov r2, #10
	vmov s2, r2
	vcvt.f32.s32 s2, s2
	ldr r2, =div_10
	vldr.f32 s3, [r2]
	vmov s15, s2
	vmul.f32 s14, s15, s2
	vmul.f32 s13, s14, s2
	vmul.f32 s12, s13, s2
	vmul.f32 q3, q3, d0[0]
	vmul.f32 q2, q3, d1[1]
	vcvt.s32.f32 q2, q2
	vcvt.f32.s32 q2, q2
	vmul.f32 q2, q2, d1[0]
	vsub.f32 q1, q3, q2
	vcvt.s32.f32 q2, q1
float_fr_save:	
	mov r2, #0x30
	vdup.s32 q3, r2
	vadd.s32 q1, q2, q3 
	vmov r2, s7
	strb r2, [r0, r1]
	add r1, r1, #1
	vmov r2, s6
	strb r2, [r0, r1]
	add r1, r1, #1
	vmov r2, s5
	strb r2, [r0, r1]
	add r1, r1, #1
	vmov r2, s4
	strb r2, [r0, r1]
	add r1, r1, #1
fill_float:
	cmp r1, r3
	bhs endfl2asc
	mov r2, #0x20
fl2asc_fill_loop:
	strb r2, [r0, r1]
	add r1, r1, #1
	cmp r1, r3
	bhs endfl2asc
	b fl2asc_fill_loop
endfl2asc:
	// pop {r1}
	mov		sp, r11
	pop     {r11}
	// ???? add r1, r1, #4	
	ldr r0, =kformat_buffer
	pop {lr}
	bx  lr

	


@************************************************************************************
@                      num_2_dec
@ 
@ Die Funktion num_2_dec konvertiert eine gegebene Zahl (im Register r1) 
@ in eine dezimale ASCII-Darstellung und speichert diese in einem internen Puffer. 
@ Der Rückgabewert r0 zeigt auf den Puffer
@ und der Rückgabewert r1 gibt die Länge des erzeugten Strings an. 
@ Die Funktion verarbeitet auch negative Zahlen 
@ und ermöglicht die Angabe einer Feldbreite (fieldwidth), 
@ um den erzeugten String entsprechend zu füllen.
@************************************************************************************

num_2_dec:	// input r1 = number to convert input r2  1 = minus else = none r3 = fieldwidth, erst noch implementieren// returnwert in r0 ist pointer auf internen Puffer // return wert in r1 ist länge des strings

			push    {lr}
			push 	{r11}
			mov 	r11, sp
			and     r2, r2, #0x3f ///////????-> useless??!
			push 	{r1, r2}
			bl      clear_buff
buff_cleared_dec:				
			pop 	{r1, r2}
			push    {r4,r5, r6, r7}
			mov     r7, r3
			cmp     r2, #1
			mov     r6, #0
			bne     dec_signed_processed
			mov     r2, #0x2d
			ldr     r3, =sign
			strb    r2, [r3]

dec_signed_processed:
			ldr     r4, =kformat_buffer
			mov     r0, #0 
			mov     r2, #10
			mov     r3, #0
			cmp     r1, #0
			bne     num_2_dec_loop
			add     r0, r1, #0x30
			push    {r0}
			add     r6, #1
			b 		num_2_dec_conv_end
num_2_dec_loop:
			mov     r3, r1      		// r3 last value
			cmp     r3, #0
			beq     num_2_dec_conv_end
			udiv    r1, r1, r2      	// r1 = r1/10 -> Integer without rest
			umull 	r0, r5, r1, r2		 
			sub     r0, r3, r0  		// r0 Rest der Division
			add     r0, #0x30
			push    {r0}
			add     r6, #1
			b		num_2_dec_loop
num_2_dec_conv_end:		
			cmp     r6, #0			// ist das nötig?
			beq     print_is_d
			mov     r1, r6 
			//nicht getestet
			//cmp     r7, #0
			//beq print_is_d
			// ab hier getestet
			subs 	r3, r7, r1  // r3 = fillwidth
			blo 	print_is_d
			mov     r0, #0x20
			mov     r5, r3
			mov     r2, #0
fill_d:
			strb    r0, [r4], #1
			add     r2, #1
			cmp     r2, r3
			blo     fill_d
print_is_d:	
			mov     r7, #0
			ldr     r3, =sign
			ldrb    r2, [r3]
			cmp     r2, #0x2d
			bne    	print_is_d_loop
			strb    r2, [r4], #1
print_is_d_loop:
			pop     {r0}
			strb    r0, [r4, r7]
			cmp     r7, r6
			add     r7, #1
			bls     print_is_d_loop
num_2_dec_end:	
			add     r1, r5, r1
			ldr     r3, =sign
			ldrb    r2, [r3]
			cmp     r2, #0x2d
			subne   r1, #1
			mov     r2, #0
			strb    r2, [r3]
			pop		{r4, r5, r6, r7}
			mov		sp, r11
			pop     {r11}
			ldr     r0, =kformat_buffer
			pop     {lr}
			bx      lr
			

@************************************************************************************
@                      num2hexascii
@ 
@ Die Funktion `num2hexascii` konvertiert eine gegebene Zahl in ihre hexadezimale ASCII-Darstellung 
@ und speichert sie in einem internen Puffer. 
@ Der Rückgabewert r0 zeigt auf den Puffer 
@ und der Rückgabewert r1 gibt die Länge des erzeugten Strings an. 
@ Die Funktion ermöglicht auch die Angabe einer Feldbreite (fieldwidth) für die Ausgabe.
@************************************************************************************
num2hexascii: // r1 input value r2 input fieldwidth - returnwert in r0 ist pointer auf internen Puffer
			push 	{lr}
			push 	{r11}
			mov 	r11, sp
			push    {r4, r5,r6}
			and     r2, r2, #0x3f 
			push 	{r1, r2}
			bl      clear_buff
buff_cleared_hex:				
			pop 	{r1, r2}
			cmp     r2, #0
			subne   r5, r2, #2
			moveq   r5, r2
			mov     r3, #0			      // ab hier eigentliche fkt!
num_2_ascii_Hex_loop:

			and     r2, r1, #0xf
			ldr 	r4, =Hex_Lookup
			ldrb	r4, [r4, r2]
			push    {r4}
			add		r3, r3, #1
			lsr		r1, r1, #4	
			cmp		r1, #0				
			bne		num_2_ascii_Hex_loop
			cmp     r3, r5
			ldr 	r4, =kformat_buffer
			bge     hex_save
			sub     r5, r5, r3
			mov     r6, #0
			
hex_fill:  
			mov     r2, #0x20
			strb    r2, [r4, r6]
			add     r6, r6, #1
			cmp     r6, r5
			blt     hex_fill
			add     r4, r4, r5

hex_save:	
			ldr     r2, =#0x30
			strb    r2, [r4]
			ldr     r2, =#0x78
			strb    r2, [r4, #1]
			add     r4, r4, #2
			mov		r1, r3
			mov     r3, #0 
			sub     r1, #1
hex_save_loop:
			pop     {r0}
			strb     r0, [r4 ,r3]
			add     r3, #1
			cmp     r3, r1
			ble     hex_save_loop
			add     r1, r1, #2
			add     r1, r1, r5
			pop     {r4,r5, r6}
			mov		sp, r11
			pop     {r11}
breakpoint: // auskommentieren - war nur für debugging
			ldr		r0, =kformat_buffer
			pop     {lr}
			bx      lr
			// output r0 ist string output r1 muss länge + fieldwidth sein, wenn fieldwidt größer länge
			
	
@************************************************************************************
@                      clear_buff
@ 
@ Die Funktion clear_buff löscht den Inhalt des internen Puffers, 
@ der für die Umwandlungen verwendet wird. Sie setzt alle Elemente des Buffers auf den Wert 0.
@************************************************************************************	
clear_buff:
			push    {lr}
			ldr 	r0, =kformat_buffer    // Buffer clear
			mov     r1, #0x00
			mov		r2, #120
			bl		memset
			pop     {lr}
			bx      lr
