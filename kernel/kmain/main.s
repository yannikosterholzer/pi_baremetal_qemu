.global KMain
// externe funktionen hier einbinden
.data
// ...
.section .text
KMain:
			push	{lr}
			push	{r11}
			mov 	r11, sp	
			
			// Code hier ...

			mov		sp, r11
			pop		{r11}
			pop		{lr}
			
			
			
