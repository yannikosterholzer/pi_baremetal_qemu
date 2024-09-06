.global MailboxWrite
.global MailboxRead


.section .data


.section .text
@ ---------MailBox-Struct----------
.equ MailboxBaseAdr, 0x3f00b880 
.equ MB_READ,              0x00
.equ MB_STATUS_WRITE, 	   0x38
.equ MB_WRITE,             0x20
.equ MB_STATUS_READ,       0x18
@ ---------------------------------
.equ channel_mask,         0x0f
.equ MAIL_FULL,      0x80000000   @ Dieses Bit ist im Statusregister gesetzt, 
                                  @ wenn kein Platz ist um in die Mailbox zu schreiben
.equ MAIL_EMPTY,     0x40000000   @ Dieses Bit ist gesetzt, wenn es in der Mailbox nichts zu lesen gibt



@************************************************************************************
@                      MailboxWrite
@ 
@ MailboxWrite schreibt eine Nachricht in die GPU-Mailbox 1 des Raspberry Pi
@************************************************************************************
MailboxWrite:                                       @ input message in r0, channel in r1
    push    {lr}
    tst     r0, #channel_mask                       @ validate mail
    bne     error_exit
    cmp     r1, #channel_mask                       @ validate channel                             
    bhi     error_exit             
    mov     r2, r0
    ldr     r0, =#MailboxBaseAdr
wait_write:
    ldr     r3, [r0, #MB_STATUS_WRITE]        	    @ Fordere Status von Mailbox 1 an
    tst     r3, #MAIL_FULL            	            @ pruefe ob die Mailbox voll ist
    bne     wait_write                              @ wenn ja -> wait_write-Schleife
wait_write_end:                                     @ wenn nein -> falle zur dieser Funktion
    add     r2, r1                		    @ Setze den Kanal als die letzten Bits der Nachricht
    str     r2, [r0, #MB_WRITE]       		    @ schreibe die Nachricht in --> mailbox 1 write register
    pop     {pc}                            
	



@************************************************************************************
@                      MailboxRead
@ 
@ MailboxRead liest eine Nachricht aus der GPU-Mailbox 0 des Raspberry Pi
@************************************************************************************

MailboxRead:                                        @ input channel in r0
    push    {lr}                                    @ push the address the function should return to
    cmp     r0, #channel_mask                       @ validate channel                           
    bhi     error_exit 
    mov     r1, r0                          
    ldr     r0, =#MailboxBaseAdr
wait_read:
    ldr     r2, [r0, #MB_STATUS_READ]              @ Fordere den Status von Mailbox0 an
    tst     r2, #MAIL_EMPTY          
    bne     wait_read                              @ Solange die Mailbox leer ist -> wait_read- Schleife
wait_read_end:
    ldr     r2, [r0, #MB_READ]                     @ Lade die Adresse der Antwort-Daten
    and     r3, r2, #channel_mask                  @ Die niedrigsten 4 Bit, sind der Kanal den wir betrachten wollen
    teq     r3, r1                                 @ pruefe ob richtiger Kanal
    bne     wait_read                              @ wenn falscher Kanal -> go to: wait_read
right_channel:
    and      r0, r2, #0xfffffff0                   @ Mailbox-response ist als Returnwert in r0
    pop      {pc}                                  @ return

error_exit:
    mov      r1, #1
    pop      {pc} 
    
