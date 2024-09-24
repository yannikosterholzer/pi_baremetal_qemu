.global irq_handler_ext
.extern kprintf
.extern read_core0_timer_pending
.extern write_cntv_tval
.extern read_cntv_tval
.extern read_cntvtv
.extern disable_cntv_irq

.equ C0_IRQSOURCE,        0x40000060                    

.section .text

	irq_handler_ext:
			  push {lr}
			  bl read_core0_timer_pending
			  cmp r0, #0x8
			  bne handle_irq_3_end
			  mvn r1, #0 					
			  bl write_cntv_tval               	@ cleare Interrrupt und setze Zählwert auf max
			  bl disable_cntv_irq			@ deaktiviere den Timerinterrupt				
	handle_irq_3_end:		
			  pop {lr}
			  bx  lr
