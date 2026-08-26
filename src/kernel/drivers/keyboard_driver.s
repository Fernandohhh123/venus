;Este archivo contiene codigo para gestionar
; el hardare de teclado



; funcion para procesar el teclado
keyboard_handler:
    push ax
	push bx
	push cx

    ; Leemos algo de la salida del teclado
    ; que ha sido puesto en el puerto 0x60
	in al, 0x60

    ; Verificamos si se presiono alguna tecla
	test al, 0x80
	jnz .fin_kb_handler ;por si no se presiono una tecla

	; Si se preciono una tecla...

    ; Hacemos la conversion de scancode a codigo ascii
    call    .scancode_to_ascii

	; Se inserta el scancode en el buffer
	xor bx, bx
	mov bl, byte [kb_buffer_head]
	mov byte [kb_buffer + bx], al
	inc bl
	and bl, 0x1F ; Filtro para no desbordar el buffer
	mov byte [kb_buffer_head], bl

    ; Reactivamos el driver de teclado
	.fin_kb_handler:
	mov al, 0x20 ;00100000b
	out 0x20, al

    pop ax
	pop cx
	pop bx
iret

.scancode_to_ascii:
	push bx

	xor bh, bh
	mov bl, al
	mov al, byte [ascii_table + bx]

	pop bx
ret
