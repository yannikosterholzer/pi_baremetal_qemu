.global enable_cntv 
.global disable_cntv
.global enable_cntv_irq
.global disable_cntv_irq
.global read_core0_timer_pending
.global read_cntvtv
.global read_cntvct
.global read_cntvoff	  
.global read_cntv_tval
.global write_cntv_tval
.global read_cntfrq

@ EQUS
.equ CTIMER_CTL,                  0x40000000                   @  Control register 
.equ C0TIMER_INTCTL,              0x40000040                   @  Core0 timers Interrupt control 
.equ C0_IRQSOURCE,                0x40000060
.section .text

@ aktiviert den virtuellen Timer
enable_cntv:											
          	  mov r1, #1
		  mcr p15, #0, r1, c14, c3, 1
		  bx  lr  
@ deaktiviert den virtuellen Timer
disable_cntv:
          	  mov r1, #0
		  mcr p15, #0, r1, c14, c3, 1
		  bx  lr
@ aktiviert den Timerinterrupt, so dass der Timer einen Interrupt auslösen kann
enable_cntv_irq:
		  ldr r0, =C0TIMER_INTCTL
		  mov r1, #0x8
		  str r1, [r0]
		  bx  lr 
@ deaktiviert den Timerinterrupt, so dass der Timer keinen Interrupt auslösen kann
disable_cntv_irq:
    		  ldr r0, =C0TIMER_INTCTL
    		  mov r1, #0x0         @ Setze auf 0, um den Interrupt zu deaktivieren
		  str r1, [r0]
    		  bx lr

@ Liest den Status des Timerinterrupts um zu prüfen, ob ein Timer-interrupt vorliegt
read_core0_timer_pending:                                       @ returnwert in r1
		  ldr r0, =C0_IRQSOURCE
		  ldr r0, [r0]
		  bx  lr   
@ Liest den aktuellen Zählerstand des Timers
read_cntvct:
		  mrrc p15, #1, r0, r1, c14                             @ r0 low 32 bit r1 high 32 bit
		  bx lr
@ Liest den Offset des Timers aus
read_cntvoff:
		  mrrc p15, #4, r0, r1, c14                             @ r0 low 32 bit r1 high 32 bit
		  bx lr
@ Liest den verbleibenden Wert bis zum nächsten interrupt
read_cntv_tval:
		  mrc p15, #0, r0, c14, c3, 0
		  bx lr
@ Lege Zählwert bis zum nächsten Interrupt fest
write_cntv_tval:                                                @ input in r1
		  mcr p15, #0, r1, c14, c3, 0
		  bx lr 
@ Liest die Zählfrequenz des Timers aus
read_cntfrq:
		  mrc p15, #0, r0, c14, c0, 0
		  bx lr




