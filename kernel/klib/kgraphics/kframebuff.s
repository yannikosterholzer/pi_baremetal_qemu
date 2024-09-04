.global FrameBufferInfo
.global FrameBufferWrite
.global InitializeFrameBuffer

.section .data
.align 16
FrameBufferInfo:
    .word        1024                            // #0 Physical Width
    .word        768                             // #4 Physical Height
    .word        1024                            // #8 Virtual Width
    .word        768                             // #12 Virtual Height
    .word        0                               // #16 GPU - Pitch
    .word        16                              // #20 Bit Depth
    .word        0                               // #24 X
    .word        0                               // #28 Y
    .word        0                               // #32 GPU - Pointer
    .word        0                               // #36 GPU - Size

.equ PHY_WIDTH,   0
.equ PHY_HEIGHT,  4
.equ VIRT_WIDTH,  8
.equ VIRT_HEIGHT, 12
.equ GPU_PITCH,   16
.equ BIT_DEPTH,   20
.equ X,           24
.equ Y,           28
.equ GPU_PTR,     32
.equ GPU_SIZE,    36

 

/*
+----+----+----+----+----+----+----+
| 31 |           ...          |  0 |
+----+----+----+----+----+----+----+
|            PHY_WIDTH             |  <--- FrameBufferInfo
+----+----+----+----+----+----+---_+
|            PHY_HEIGHT            | 
+----+----+----+----+----+----+----+
|            VIRT_WIDTH            | 
+----+----+----+----+----+----+----+
|           VIRT_HEIGHT            |  
+----+----+----+----+----+----+----+
|            GPU_PITCH             |  
+----+----+----+----+----+----+----+
|            BIT_DEPTH             |  
+----+----+----+----+----+----+----+
|                X                 | 
+----+----+----+----+----+----+----+
|                Y                 | 
+----+----+----+----+----+----+----+
|             GPU_PTR              | 
+----+----+----+----+----+----+----+
|            GPU_SIZE              | 
+----+----+----+----+----+----+----+
 */
.section .text

@************************************************************************************
@                      InitializeFrameBuffer
@ 
@ Die Funktion `InitializeFrameBuffer` initialisiert den Framebuffer für die Anzeige auf dem Bildschirm. 
@ Sie überprüft zunächst die Eingabeparameter auf Gültigkeit. 
@ Wenn die Eingaben gültig sind, werden die entsprechenden Informationen im Framebuffer gespeichert 
@ und der Framebuffer zurückgesetzt. Anschließend wird der initialisierte Framebuffer geschrieben. 
@ Die Funktion gibt die Adresse des Framebuffer-Informationsspeichers zurück, 
@ wenn die Initialisierung erfolgreich war, andernfalls gibt sie 0 zurück.
@************************************************************************************
InitializeFrameBuffer:                    @ input r0 = width r1 = height r2 = bitDepth
    cmp   r0, #4096                       @ Prüfe ob die Breite 
    cmpls r1, #4096                       @ und Höhe kleiner oder gleich 4096 sind 
    cmpls r2, #32                         @ und ob die Farbtiefe kleiner oder gleich 32 ist. 
wrong_input_ret:	
    movhi r0, #0                          @  falls das nicht der fall ist, return 0
    movhi pc, lr  
right_input_continue:	                  @ Initialisiere die FrameBufferInfo-Struktur mit den Inputwerten
    push  {r4, lr}                        @ speichere Returnadresse und r4, da es ansonsten nach Ende Funktion modifiziert wäre 
    ldr   r4, =FrameBufferInfo    
    str   r0, [r4, #PHY_WIDTH]             
    str   r1, [r4, #PHY_HEIGHT]       
    str   r0, [r4, #VIRT_WIDTH]         
    str   r1, [r4, #VIRT_HEIGHT]       
    str   r2, [r4, #BIT_DEPTH]     
reset_frame_buff:
    mov   r1, #0
    str   r1, [r4, #GPU_PITCH]            
    str   r1, [r4, #X]
    str   r1, [r4, #Y]
    str   r1, [r4, #GPU_PTR]
    str   r1, [r4, #GPU_SIZE]
    mov   r0, r4
    bl    FrameBufferWrite                
    teq   r0, #0                        // check returnvalue
return_failed:	
    movne r0, #0                        // if result not equal to 0, set result to 0
    popne {r4, pc}                        
return_success:
    mov   r0, r4                        // mov frame buffer info address to r0
    pop   {r4, pc}                        


@************************************************************************************
@                      FrameBufferWrite
@ 
@ Die Funktion `FrameBufferWrite` fordert die Aktualisierung des Framebuffers an, 
@ indem sie eine Nachricht in den Mailbox-Kanal 1 schreibt. 
@ Anschließend liest sie die Antwort aus dem Mailbox-Kanal 1, 
@ um den Erfolg der Aktualisierung zu überprüfen.
@************************************************************************************
FrameBufferWrite:
    push {lr}
    orr  r0, #0xC0000000                 @ Speicheradresse für GPU anpassen bei deaktiviertem L2-Cache
    mov  r1, #1                          @ Kanal 1: Framebuffer
    bl   MailboxWrite                    @ Sende die Mail an die GPU
    cmp  r0, #0
    bne  FrameBufferWriteError
    mov  r0, #1                          @ Kanal 1: Framebuffer
    bl   MailboxRead                     @ Lese die Antwortmail der GPU
    cmp  r0, #0
    bne  FrameBufferWriteError
    pop  {pc}

FrameBufferWriteError:
    mov  r0, #1
	pop  {pc}
	
	
	
	
	
	
	
	
	
	
	
	












