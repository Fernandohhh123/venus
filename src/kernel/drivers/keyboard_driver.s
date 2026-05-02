;Este archivo contiene codigo para gestionar
; el hardare de teclado



; funcion para procesar el teclado
.keyboard_handler:
	push bx
	push cx

	in al, 0x60 ;leemos scancode

	test al, 0x80
	jnz .fin_kb_handler ;por si no se presiono una tecla

	;si se preciono una tecla
	; se inserta el scancode en el buffer
	xor bx, bx
	mov bl, byte [kb_buffer_head]
	mov byte [kb_buffer + bx], al
	inc bl
	and bl, 0x0F ;forzamos 0 en bh
	mov byte [kb_buffer_head], bl

	.fin_kb_handler:
	mov al, 0x20 ;00100000b
	out 0x20, al

	pop cx
	pop bx
iret
