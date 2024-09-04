//evtl .data zu .k_lib_data umbennen

.global memset //arg: ptr, initval, size
.global memcpy // dst = r0 src = r1 size = r3
.global memcmp // src1 = r0 src2 = r1 size = r2

.section .text


@************************************************************************************
@                      memset
@ 
@ Die Funktion `memset` setzt `size` Bytes ab der Adresse `ptr` auf den Wert `initval`. 
@ Sie durchläuft den Speicherbereich in umgekehrter Reihenfolge und setzt jedes Byte auf den angegebenen Wert. 
@ Die Schleife endet, wenn die Größe 0 erreicht ist.
@************************************************************************************
memset: // ptr = r0 initval = r1 size = r2
	cmp r2, #0
	beq memset_end
	sub r2, r2, #1
	strb r1, [r0, r2]
	b memset
memset_end:
	bx lr


@************************************************************************************
@                      memcpy
@ 
@ Die Funktion `memcpy` kopiert `size` Bytes von der Quelladresse `src` zur Zieladresse `dst`.                                                                                       
@ Wenn die Zieladresse größer als die Quelladresse ist, erfolgt die Kopie in aufsteigender Reihenfolge. 
@ Andernfalls erfolgt die Kopie in absteigender Reihenfolge. 
@ Die Schleife kopiert byteweise die Daten und endet, wenn die Kopie abgeschlossen ist.
@************************************************************************************
//memcpy implementieren: durch 4 teilbar? durch 8 teilbar? durch 16 teilbar? usw -> zusätzliche schnellere varianten
memcpy:// dst = r0 src = r1 size = r3
	cmp 	r1, r0
	bhi	memcpy_forward
	add 	r3, r1, r2
	cmp 	r0, r3
	bhi 	memcpy_forward
memcpy_reverse:
	subs 	r2, r2, #1
	ldrb 	r3, [r1, r2]
	strb 	r3, [r0, r2]
	beq 	memcpy_end
	b 	memcpy_reverse
	b	.
memcpy_forward:
	ldrb 	r3, [r1], #1
	strb 	r3, [r0], #1
	subs 	r2, r2, #1
	bgt 	memcpy_forward
memcpy_end:
	bx 	lr
	b	.



@************************************************************************************
@                      memcmp
@ 
@ Die Funktion `memcmp` vergleicht zwei Speicherbereiche `src1` und `src2` der Größe `size`. 
@ Sie durchläuft die Speicherbereiche byteweise, indem sie jeweils ein Byte aus jedem Bereich lädt und vergleicht. 
@ Wenn ein Unterschied festgestellt wird, wird der Wert 1 in `r0` gesetzt, andernfalls bleibt `r0` unverändert. 
@ Die Schleife wird beendet, wenn die Größe 0 erreicht ist oder ein Unterschied festgestellt wurde.
@************************************************************************************

//noch nicht geprüft
memcmp: // src1 = r0 src2 = r1 size = r2
	mov	r3, r0
	mov 	r0, #0
	push    {r4, r5}
mem_cmp_loop:	
	cmp 	r2, #0
	beq 	mem_cmp_end
	ldrb 	r4, [r3], #1
	ldrb 	r5, [r1], #1
	cmp	r4, r5
	bne 	mem_cmp_ne
	subs 	r2, r2, #1
	b 	mem_cmp_loop
mem_cmp_ne:
	mov 	r0, #1
mem_cmp_end:
	pop     {r4, r5}
	bx 	lr
