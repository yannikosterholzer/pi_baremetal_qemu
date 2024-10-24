.global num_2_dec
.global num2hexascii
.global float2ascii
.section .data

 div_10:                .float  0.1 
 sign:                  .byte 0x0
			.balign 4
 num2dec_buffer:
			.space 16, 0x0
	 

 Hex_Lookup:	        .asciz "0123456789ABCDEF"
                        .balign 4
 kformat_buffer:	       
			.space 120, 0x0
 Hexres:                .ascii "0", "x"
 kformat_buffer_reverse:	       
			.space 120, 0x0
	 		.balign 4

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
float2ascii: 	@ input : r1 = Floatwert, der zu String umgewandelt werden soll
                @ output: r0 = Adresse des erzeugten Strings
                @         r1 = Stringlänge
@ -----------------------------------------------------------------  
			push {lr}
			push {r11}
			mov  r11, sp
			vmov s0, r1
float_asc:	
			vcmpe.f32 s0, #0
			vmrs APSR_nzcv, FPSCR
			movmi r2, #1
			vabs.f32 s0, s0
			vcvt.s32.f32 s1, s0
			vmov r0, s1
			vcvt.f32.s32 s1, s1
			vsub.f32 s0, s0, s1
			mov r1, r0
			mov r3, #0
			bl num_2_dec
fraction:
			add r1, r1, #1
			mov r2, #0x2e
			strb r2, [r0, r1]
			add r1, r1, #1
			mov r2, #10
			vmov s2, r2
			vcvt.f32.s32 s2, s2
			vmov.f32 s3, #1   
			vdiv.f32 s3, s3, s2	
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
endfl2asc:
			mov sp, r11
			pop {r11}	
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

num_2_dec:	@ input : r1 = Wert, der als Dezimalzahl in einen String dargestellt werden soll
		@	  r2 = 0 für negativen Wert; 1 für positive Werte
                @ output: r0 = Adresse des erzeugten Strings
                @         r1 = Stringlänge
@ -----------------------------------------------------------------  
			push {lr}
			push {r11}
			mov r11, sp
			and r2, r2, #0x3f 
			push {r1, r2}
			bl  clear_buff
buff_cleared_dec:				
			pop {r1, r2}
			push {r4,r5, r6, r7}
			cmp r2, #1
			mov r6, #0
			bne dec_signed_processed
			mov r2, #0x2d
			ldr r3, =sign
			strb r2, [r3]

dec_signed_processed:
			ldr r4, =kformat_buffer
			mov r0, #0 
			mov r2, #10
			mov r3, #0
			cmp r1, #0
			bne num_2_dec_loop
			add r0, r1, #0x30
			push {r0}
			add r6, #1
			b num_2_dec_conv_end
num_2_dec_loop:
			mov r3, r1      		
			cmp r3, #0
			beq num_2_dec_conv_end
			udiv r1, r1, r2      	
			umull r0, r5, r1, r2		 
			sub r0, r3, r0  		
			add r0, #0x30
			push {r0}
			add r6, #1
			b num_2_dec_loop
num_2_dec_conv_end:		
			cmp r6, #0			
			beq print_is_d
			mov r1, r6 
			mov r5, r3	
print_is_d:	
			mov r7, #0
			ldr r3, =sign
			ldrb r2, [r3]
			cmp r2, #0x2d
			bne print_is_d_loop
			strb r2, [r4], #1
print_is_d_loop:
			pop {r0}
			strb r0, [r4, r7]
			cmp r7, r6
			add r7, #1
			bls print_is_d_loop
num_2_dec_end:	
			add r1, r5, r1
			ldr r3, =sign
			ldrb r2, [r3]
			cmp  r2, #0x2d
			subne r1, #1
			mov r2, #0
			strb r2, [r3]
			pop {r4, r5, r6, r7}
			mov sp, r11
			pop {r11}
			ldr r0, =kformat_buffer
			pop {lr}
			bx lr
			

@************************************************************************************
@                      num2hexascii
@ 
@ Die Funktion `num2hexascii` konvertiert eine gegebene Zahl in ihre hexadezimale ASCII-Darstellung 
@ und speichert sie in einem internen Puffer. 
@ Der Rückgabewert r0 zeigt auf den Puffer 
@ und der Rückgabewert r1 gibt die Länge des erzeugten Strings an. 
@ Die Funktion ermöglicht auch die Angabe einer Feldbreite (fieldwidth) für die Ausgabe.
@************************************************************************************
num2hexascii:   @ input : r1 = Wert, der als Hexadezimalzahl in einen String dargestellt werden soll
                @ output: r0 = Adresse des erzeugten Strings
                @         r1 = Stringlänge
@ -----------------------------------------------------------------
			push {lr}
			push {r11}
			mov r11, sp
			push {r4, r5,r6}
			push {r1, r2}
			bl  clear_buff
			bl  clear_buff_rev
buff_cleared_hex:				
			pop {r1, r2}
			mov r5, #0
			mov r3, #0			      
num_2_ascii_Hex_loop:
			and r2, r1, #0xf
			ldr r4, =Hex_Lookup
			ldrb r4, [r4, r2]
			push {r4}
			add r3, r3, #1
			lsr r1, r1, #4	
			cmp r1, #0				
			bne num_2_ascii_Hex_loop
			mov r5, r3
			ldr r4, =kformat_buffer_reverse
			bge hex_save
hex_save:	
			mov r1, r3
			mov r3, #0 
			sub r1, #1
hex_save_loop:
			pop {r0}
			strb r0, [r4 ,r3]
			add r3, #1
			cmp r3, r1
			ble hex_save_loop
			ldr r0, =kformat_buffer_reverse
			ldr r2, =kformat_buffer
			sub r5, r5, #1
			mov r1, r5
hex_reverse:
			push {r1}
			ldrb r3, [r0], #1
			strb r3, [r2, r1]
			subs r1, r1, #1
			bge hex_reverse
			pop {r1}
			mov r1, r5
			add r1, r1, #2
			pop {r4,r5, r6}
			mov sp, r11
			pop {r11}
			ldr r0, =Hexres
			pop {lr}
			bx lr
			
	
@************************************************************************************
@                      clear_buff
@ 
@ Die Funktion clear_buff löscht den Inhalt des internen Puffers, 
@ der für die Umwandlungen verwendet wird. Sie setzt alle Elemente des Buffers auf den Wert 0.
@************************************************************************************	
clear_buff:
			push {lr}
			ldr r0, =kformat_buffer    // Buffer clear
			mov r1, #0x00
			mov r2, #120
			bl memset
			pop {lr}
			bx lr
clear_buff_rev:
			push {lr}
			ldr r0, =kformat_buffer_reverse    // Buffer clear
			mov r1, #0x00
			mov r2, #120
			bl memset
			pop {lr}
			bx lr
			
