.global delay_ms

.section .text


delay_ms:                           @ r1 = delay in ms
    push {lr}
    push {r1}
    cpsid if 
    bl read_cntfrq                  @ r0 = freq
    pop {r1}
    
    @ Berechne den Zählwert und setze den Timer entsprechend
    ldr r2, =#1000
    udiv r0, r0, r2                 @ r0 = freq /1000
    mul r0, r0, r1                  @ r0 = r0 * n
    udiv r1, r0, r2
    bl write_cntv_tval
    bl enable_cntv_irq              @ enable den Interrupt
    bl enable_cntv
    wfi                             @ wait for interrupt
    bl disable_cntv
    cpsie i
    pop {pc}

