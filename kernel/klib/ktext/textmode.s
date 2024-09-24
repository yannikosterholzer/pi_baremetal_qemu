.global textmode_get_tabentry
.global textmode_init
.extern canvas_base
.extern textmode_state

.equ tab_length, 80 * 60       
.equ row_length, 80     
.equ row_offset, 8
  

.text
textmode_init:
            push {lr}
            ldr  r0, = textmode_state
            ldr  r1, [r0]
            cmp  r1, #0
            bne  textmode_init_end
            mov  r1, #0xf
            str  r1, [r0]
            bl   canvas_init
	          ldr  r1, =0x0
	          bl   fillscreen
textmode_init_end:
            pop  {pc}
    


textmode_get_tabentry:              @ r1 = index r2 = hintergrundfarbe
			      push {lr}
			      push {r11}
			      mov  r11, sp
            sub  sp, sp, #8
            str  r2, [r11, #-4]	    @ speichere hintergrunfarbe auf dem Stack
            ldr  r2, =canvas_base
            ldr  r2, [r2]
            str  r2, [r11, #-8]	    @ speichere Basisadresse der Leinwand
calc_tabindex:
            mov  r3, #tab_length
            @ r0 = r1 mod r3
            udiv r0, r1, r3
            mul  r2, r0, r3
            sub  r0, r1, r2
            cmp  r0, #0
            bne  calc_columnrowindex
            @ Neue "Seite" -> Bildschirm-reset
            push {r0, r1}
            ldr  r1, [r11, #-4]     @ lade hintergrundfarbe
            bl   fillscreen
            pop  {r0, r1}
calc_columnrowindex:
@	spaltenindex = tabindex modulo reihengröße
@	reihenindex =  tabindex / reihengröße
            mov  r3, #row_length
            udiv r1, r0, r3         @ r1 = Reihenindex 
            mul  r2, r1, r3
            sub  r0, r0, r2         @ r0 = Spaltenindex
calculate_element_addr:
@	Elementadresse = Basisadresse + (Spaltenindex + (Reihengröße x Reihenoffset  x Reihenindex)) x Elementgröße
            mov r2, #row_offset
            mul r2, r2, r3          @ r2 = rowoffset x rowlength
            mul r1, r1, r2          @ r0 = r2 x rowindex
            add r0, r1, r0
            ldr r2, [r11, #-8]      @ Basisadresse
            add r0, r2, r0, lsl #4  @ Basisadresse + Index x Elementgröße         
            mov	sp, r11
			      pop	{r11}
			      pop	{pc}

