.global canvas_init
.global put_pixel
.global fillscreen
.global drawline
.global put_pixel

.extern InitializeFrameBuffer

.section .data
.align 4

	canvas_base: .word 0x0
	canvas_error_string: .asciz "canvas_error could not init framebuff /n ________________________ /n"
.section .text

	.equ SCREEN_WIDTH,  1024
	.equ SCREEN_HEIGHT, 768
	.equ BIT_DEPTH,     16
	.equ CWh,           1024
	.equ CHh,           384
	.equ Xwidth,        2048
	.equ SCREEN_MAX,    1024 * 768   


@************************************************************************************
@                      canvas_init
@ 
@ Die Funktion canvas_init initialisiert einen Framebuffer für die Bildschirmausgabe. 
@ Sie ruft InitializeFrameBuffer auf, um den Framebuffer zu initialisieren. 
@ Wenn die Initialisierung erfolgreich ist, wird die Basisadresse des Framebuffers gespeichert. 
@ Andernfalls wird eine Fehlerbehandlung durchgeführt.
@************************************************************************************
canvas_init:
		push {lr}
   		mov r0, #SCREEN_WIDTH
    		mov r1, #SCREEN_HEIGHT
    		mov r2, #BIT_DEPTH
   		bl  InitializeFrameBuffer       @ initialize the frame buffer and return its address in r0
   	 	teq r0, #0                      @ check if function result is 0 (error)
    		beq canvas_error                @ handle error -> ersetze durch ein printf!
store_canv_base_adr:
   		ldr r3, [r0, #32]		@ canvas ptr
   		and r3, #0x3FFFFFFF             @ convert bus address to physical address used by the ARM CPU
		ldr r1, =canvas_base
		str r3, [r1]
		pop {lr}
		bx lr
	
@************************************************************************************
@                      canvas_error
@ 
@ Die `canvas_error`-Funktion gibt eine Fehlermeldung aus, 
@ wenn beim Initialisieren des Framebuffers ein Fehler auftritt
@ und führt dann eine Endlosschleife aus, um die Ausführung an dieser Stelle zu stoppen.
@************************************************************************************		
canvas_error:
		ldr r1, =canvas_error_string
		mov r2, #2
		bl kprintf        //r1 = formatstring / r2 = OUT_TYPE 	
		b  canvas_error
	
	
@************************************************************************************
@                      fillscreen
@ 
@ Die Funktion `fillscreen` füllt den gesamten Bildschirm mit einer bestimmten Farbe, 
@ die im Register r1 angegeben ist. Sie verwendet die Adresse des Framebuffers, 
@ um den Bildschirm zu aktualisieren, und durchläuft dann jeden Pixel im Framebuffer, 
@ um ihn mit der angegebenen Farbe zu füllen.
@************************************************************************************	
fillscreen: //color in r1	
		mov r0, r1
		mov r1, #SCREEN_HEIGHT                   @ set y with the first row pixel
		ldr r3, =canvas_base
		ldr r3, [r3]
drawRow:
    		mov r2, #SCREEN_WIDTH                    @ set x with the first screen row
drawPixel:
    		strh r0, [r3]     			 @ store low half word at fb pointer
    		add r3, #2          			 @ skip half word to the next address
    		sub r2, #1               	         @ subtract 1 from the screen width
   		teq r2, #0                               @ check if x reaches 0
   		bne drawPixel                            @ proceed to next pixel
    		sub r1, #1                               @ decrement screen height
    		teq r1, #0                               @ check of y reaches 0
    		bne drawRow                              @ proceed to next row
		bx  lr

 
@************************************************************************************
@                      get_canv_x
@ 
@ Die Funktion get_canv_x konvertiert eine Benutzer-x-Koordinate 
@ in das ein Canvas-Koordinatensystem, 
@ wobei der Bildschirmmittelpunkt dem User als Ursprung dient 
@ und das Canvas-Koordinatensystem oben links beginnt.
@************************************************************************************	
get_canv_x:                             @ input r1 = User_x coord -> output r0 = canv_x
		push {r1}
		ldr r0, =#CWh
		add r0, r0, r1
		pop {r1}
		bx lr
@************************************************************************************
@                      get_canv_y
@ 
@ Die Funktion get_canv_y konvertiert eine Benutzer-y-Koordinate 
@ in das ein Canvas-Koordinatensystem, 
@ wobei der Bildschirmmittelpunkt dem User als Ursprung dient 
@ und das Canvas-Koordinatensystem oben links beginnt.
@************************************************************************************	
get_canv_y:                                @ input r1 = User_y coord -> output r0 = canv_y
		push {r1-r2}
		ldr r0, =#CHh
		mov r2, #0
		sub r1, r0, r1
		ldr r0, =#Xwidth
		mul r0, r1, r0
		pop {r1-r2}
		bx lr
	

	

@************************************************************************************
@                      put_pixel 
@ 
@ Die Funktion put_pixel setzt einen Pixel an den angegebenen Benutzerkoordinaten mit einer bestimmten Farbe. 
@ Zuerst werden die Grenzen überprüft, um sicherzustellen, dass die Koordinaten innerhalb des Bildschirms liegen. 
@ Dann werden die Benutzerkoordinaten in Canvas-Koordinaten umgerechnet, bevor der Pixel auf dem Canvas gesetzt wird.
@************************************************************************************	
put_pixel:                                  @ input r1 = User_x r2 = User_y r3 = color
		push {lr}
check_lims:
		ldr r0, =#CWh
		cmp r1, r0
		bge put_pixel_end_debug
		ldr r0, =#CHh
		cmp r2, r0
		bge put_pixel_end_debug
conv_to_canv_coord:
		bl  get_canv_x
		push {r0}
		mov r1, r2
		bl  get_canv_y
		mov r2, r0
		pop {r1}
		cmp r1, #0
		blt put_pixel_end       @  canvas_cords < 0 not allowed
		cmp r2, #0 
		blt put_pixel_end       @  canvas_cords < 0 not allowed
		bl canvas_put_pixel
		b put_pixel_end
put_pixel_end_debug:                    @ noch zu implementieren
		nop
		nop
		nop
put_pixel_end:	
		pop {lr}
		bx lr


@************************************************************************************
@                      canvas_put_pixel 
@ 
@ Die Funktion `canvas_put_pixel` setzt einen Pixel an den angegebenen Canvas-Koordinaten mit einer bestimmten Farbe. 
@ Sie verwendet die Basisadresse des Framebuffers, um auf den entsprechenden Speicherort im Framebuffer zuzugreifen, 
@ und speichert dann die Farbinformation des Pixels an dieser Position.
@************************************************************************************	
canvas_put_pixel:                           @ input r1 = canvas_x r2 = canvas_y r3 = color
		ldr r0, =canvas_base
		ldr r0, [r0]
    		add r1, r1, r2
		strh r3, [r0, r1]
		bx lr
	

@************************************************************************************
@                      drawline
@ 
@ Die Funktion `drawline` zeichnet eine horizontale Linie zwischen den gegebenen Benutzer-x-Koordinaten 
@ `User_x0` und `User_x1` bei der angegebenen Benutzer-y-Koordinate `User_y` in der angegebenen Farbe. 
@ Sie setzt Pixel entlang der Linie, indem sie die Funktion `put_pixel` aufruft.
@************************************************************************************
drawline:                                    @ input r0 = User_x1 r1 = User_x0 r2 = User_y r3 = color
		push {lr}
		push {r11}
		mov r11, sp
drawline_loop:
		cmp  r1, r0
		bge drawline_fin
		push {r0-r3}
		bl put_pixel
		pop {r0-r3}
		add  r1, r1, #2 //??
		b drawline_loop
drawline_fin:	
		mov sp, r11
		pop {r11}
		pop {lr}
		bx  lr



 
	
	
	
