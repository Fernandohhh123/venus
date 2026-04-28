;Este archivo contiene funciones para manejar
; el chip de video vga

;bx = cursor offset screen
.vga_gotoxy:
	push ax
	push bx
	push dx

	; accedemos a la parte alta del registro de posicion
	;  E
	mov dx, 0x03D4
	mov al, 0x0E
	out dx, al

	mov dx, 0x03D5
	mov al, bh
	out dx, al

	; parte baja del registro de posicion para el cursor
	;  F
	mov dx, 0x03D4
	mov al, 0x0F
	out dx, al

	mov dx, 0x03D5
	mov al, bl
	out dx, al

	pop dx
	pop bx
	pop dx
ret
