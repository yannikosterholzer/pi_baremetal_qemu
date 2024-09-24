.global textmode_state
.global text_printchar
.global text_inc_table_index
.global text_newline
.global text_del
.global text_current_index
.extern char_base
.extern textmode_get_tabentry


.section .data 
    table_index:    .word 0x00          @ Welches 8x8 Element soll beschrieben werden?
    textmode_state: .word 0x00          @ damit beim einlesen auch auf Bildschirm ausgegeben werden kann


.section .text

text_printchar: @ r1 = ascii
	  push {lr}
	  push {r11}
	  mov  r11, sp
    push {r4 -r6}
    
@ enter?
    cmp r1, #0xa
    beq text_pr_newline
    
@ select char
    ldr r0, =char_base
    lsl r1, r1, #7
	  add r0, r0, r1
    push {r0}
    ldr  r1, =table_index
    ldr  r1, [r1]
    mov  r2, #0
    bl   textmode_get_tabentry              @ r0 = 8x8-Block-Base-Adresse
    pop  {r1}                               @ r1 = Charakter_base-Adresse
	  mov  r3,  #0
	  mov  r4, #0
	  mov  r5, #0
	  mov  r6, #0
rowloop:
	  add  r5, r3, r6
	  ldrh r2, [r1]
	  add  r1, r1, #2
  	strh r2, [r0, r5]
	  add  r3, r3, #2
	  cmp  r3, #16
	  bhs  rowloopend
	  b rowloop
rowloopend:
	  mov r3, #0
	  cmp r4, #7
	  bhs colend
	  add r4, r4, #1
	  ldr r5, =1280
	  mul r6, r4, r5
	  b rowloop
colend:
    bl text_inc_table_index
    b  text_pr_end
text_pr_newline:
    bl text_newline
text_pr_end:
    pop {r4 - r6}
    mov	sp, r11
	  pop	{r11}
	  pop	{pc}


text_inc_table_index:
    ldr r0, =table_index
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    bx  lr 

text_del:
    ldr r0, =table_index
    ldr r1, [r0]
    sub r1, r1, #2
    str r1, [r0] 
    bx  lr 

.equ row_length, 80 
text_newline:
    ldr r0, =table_index
    mov  r3, #row_length
    ldr  r1, [r0]    
    udiv r2, r1, r3         @ r1 = Reihenindex-alt 
    add  r2, r2, #1
    mul  r1, r2, r3
    str  r1, [r0]
    bx   lr


text_current_index:
    push {lr}
    mov  r1, #0
    bl   text_printchar @ r1 = ascii
    ldr r0, =table_index
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]
	  pop	{pc}
    bx  lr 
