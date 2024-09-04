.section .vector_table 
.extern start                 @ startpunkt in boot.s
.extern irq_handler_ext
.global vector

 
.section .text
			.balign 32
vector:
    		ldr pc, reset_handler
    		ldr pc, undefined_handler
    		ldr pc, swi_handler
    		ldr pc, prefetch_handler
    		ldr pc, data_handler
    		ldr pc, unused_handler
    		ldr pc, irq_handler
    		ldr pc, fiq_handler

	
reset_handler:      .word reset
undefined_handler:  .word hang
swi_handler:        .word hang
prefetch_handler:   .word hang
data_handler:       .word hang
unused_handler:     .word hang
irq_handler:        .word irq
fiq_handler:        .word hang
 


reset:
		b start
		b .

@ Timerinterrupt
irq:
		
		cpsid i                        @ interrupts ausmaskieren
		push {r0-r3, r12, lr}          @ speichere Prozessorstatus
		bl irq_handler_ext             @ springe zu Extended Interrupt Handler
		pop {r0-r3, r12, lr}           @ prozessorstatus wiederherstellen
		cpsie i                        @ interrupts werden wieder durchgelassen
		sub pc, lr, #4                 @ returnadresse anpassen

@ Dauerschleife	bei nicht implementierten Interrupts
hang:
		wfi
		b hang
		
