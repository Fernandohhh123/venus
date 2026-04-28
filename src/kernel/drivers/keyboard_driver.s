;Este archivo contiene codigo para gestionar
; el hardare de teclado



; funcion para procesar el teclado
; devuelve el scancode en el registro dl
.keyboard_handler:
	push ax
	push bx

	in al, 0x60 ;leemos scancode

	test al, 0x80
	jnz .fin_kb_handler ;por si no se presiono una tecla

	;si se preciono una tecla
	xor bx, bx
	mov bl, byte [kb_buffer_head]
	mov byte [kb_buffer + bx], al
	inc bl
	and bl, 0x0F ;forzamos 0 en bh
	mov byte [kb_buffer_head], bl

	;----debug----
	;mov bl, al
	;add bl, '0'
	;call .putchar
	;-------------


	.fin_kb_handler:
	mov al, 0x20 ;00100000b
	out 0x20, al

	pop bx
	pop ax
iret
