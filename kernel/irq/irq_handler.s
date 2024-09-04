.global irq_handler_ext

.extern kprintf
.extern read_core0_timer_pending
.extern write_cntv_tval
.extern read_cntv_tval
.extern read_cntvtv
.extern cntfrq

.equ C0_IRQSOURCE,                0x40000060                    

.section .data
	teststring: .asciz "Test Timer: %15x(sec)  %15d (dec)/n ________________________ /n"	
	timer: .word 0x0
.section .text

	irq_handler_ext:

			  push {lr}
			  bl read_core0_timer_pending
			  cmp r0, #0x8
			  bne handle_irq_3_end
			  ldr r1, =cntfrq
			  ldr r1, [r1] // clear interrupt and set next timer
			  bl write_cntv_tval                                           
			
			//Test
			  ldr     r1, =timer
			  ldr     r0, [r1]
			  ldr     r1, =teststring
			  mov     r2, #2
			  push {r0}
			  push {r0}
			  bl kprintf
			  pop  {r0}
			  pop  {r0}
			  ldr     r1, =timer
			  add     r0, r0, #100
			  str     r0, [r1]
			  
			  
			//Testend
				
	handle_irq_3_end:		
			  pop {lr}
			  bx  lr
