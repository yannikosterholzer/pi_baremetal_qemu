.global start
.extern KMain
.extern k_uart0_init
.extern vector	

//equs fuer modes und stackadressen!
.equ   MODE_MASK,              0x1F
.equ   MODE_USR,               0x10
.equ   MODE_IRQ,               0x12
.equ   MODE_SVC,               0x13
.equ   STACK_IRQ,            0x7000
   
//   OS_STACK als equs!

.section .text
	//define label start
	start:
				@ interrupts ausmaskieren				
				cpsid if 
				@ register initialisieren
				mov r0, #0
				mov r1, #0
				mov r2, #0
				mov	r3, #0
				mov r4, #0
				mov r5, #0
				mov r6, #0
				mov r7, #0
				mov r8, #0
				mov r9, #0
				mov r10, #0
				mov r11, #0
				mov r12, #0
				
		@ wenn der aktive core != core0 -> sleep
		which_core:
				@ mpidr = multiprocessor affinity register enthaelt info bzgl corenr.
				mrc p15, #0, r0, c0, c0, #5
				and r0, r0, #3
				cmp r0, #0 		
				@ sleep				
				bne		.
		
		
		@ pruefe das privigierungslevel des aktiven cores 
		check_pl:	
                mrs r0, cpsr  
                mov r1, #MODE_MASK
                and r2, r0, r1
                cmp r2, #MODE_SVC
                bne sleep

			@ setze vector-adresse
				ldr r0, =vector
				mcr p15, #0, r0, c12, c0, 0
				
    		  @ Wechsel in den Interruptmodus
                mrs r0, cpsr  
                mvn r1, #MODE_MASK
                and r0, r1
                orr r0, #MODE_IRQ
                msr cpsr, r0
                
              @ Stack für Interruptmodus aufsetzen
                mov sp, #STACK_IRQ
                                
              @ Wechsle zurück in den Supervisor Modus
                mrs r0, cpsr  
                mvn r1, #MODE_MASK
                and r0, r1
                orr r0, #MODE_SVC
                msr cpsr, r0
				
        @ enable Neon-Coprozessor
		        mrc p15, 0, r0, c1, c1, 2
				orr r0, r0, #(3<<10)          @ enable neon
				bic r0, r0, #(3<<14)          @ clear nsasedis/nsd32dis /// !!!!!!! hierfür equs!
				mcr p15, 0, r0, c1, c1, 2
				ldr r0, =(0xF << 20)
				mcr p15, 0, r0, c1, c0, 2
				mov r3, #0x40000000 
				vmsr FPEXC, r3
				
		@ enable interrupts
				cpsie i  
		
		@ Aufruf der Mainfunktion
		kernel_entry:
				mov sp, #0x80000
				bl k_uart0_init
				bl 	KMain 	
				b  .    	@ wenn main verlassen wird -> hier Dauerschleife
							
sleep:
				b sleep						
					