
;------------------------------------------------
;seccion para manejar flujo de salida de datos
;
;------------------------------------------------

; Funcion para limpiar la consola
;ah = ?
.clear_screen:
	push es
	push di
	push ax
	push bx
	push cx

	xor ax, ax
	xor bx, bx
	mov al, byte [screen_char_len_x]
	mov bl, byte [screen_char_len_y]
	mul bx
	mov bx, 2
	mul bx

	mov bl, byte [text_color]

	mov di, 0xb800
	mov es, di
	xor di, di

	.loop_clean_vram:
	mov byte [es:di], 0x20 ;caracter espacio
	inc di
	mov byte [es:di], bl
	inc di
	cmp di, ax
	jge .done_clean_vram
	jmp .loop_clean_vram
	.done_clean_vram:

	mov bx, 0x0000
	call .gotoxy

	pop cx
	pop bx
	pop ax
	pop di
	pop es
ret


; Funcion para imprimir cadenas de caracteres
; ah = 0x02
; bx = puntero al string, debe terminar con 0
.print_str:
	push es
	push di
	push ax

	mov ax, ds
	mov es, ax

	mov di, bx

	; es:di
	.loop_print:

	mov al, [es:di]
	inc di
	or al, al
	jz .done
	call .putchar
	jmp .loop_print
	.done:

	pop ax
	pop di
	pop es
ret


; Funcion para poner un caracter en la posicion actual del cursor
; ah = 0x01
; al = ascii
.putchar:
	push ax
	push bx
	push es
	push di

	; colocamos el color del texto
	mov bh, byte [text_color]

	;nos colocamos en la memoria de video
	mov di, 0xb800
	mov es, di
	mov di, word [cursor_offset_memory]

	;comprobamos que es un caracter especial
	cmp al, 0x20
	jge .put_normal_char
	call .process_special_char
	jmp .done_putchar

	.put_normal_char:
	mov byte [es:di], al
	inc di
	mov byte [es:di], bh
	inc di
	mov word [cursor_offset_memory], di

	; actualizamos la posicion del cursor
	mov al, byte [cursor_x]
	mov ah, byte [screen_char_len_x]

	; verificamos si esta en el final de la pantalla
	cmp al, ah
	je .print_new_line

	mov bh, byte [cursor_x]
	inc bh
	mov bl, byte [cursor_y]
	call .gotoxy
	jmp .done_update_cursor

	.print_new_line:
	xor bh, bh ; x = 0
	mov bl, byte [cursor_y] ; y += 1
	inc bl
	call .gotoxy
	.done_update_cursor:
	.done_putchar:

	pop di
	pop es
	pop bx
	pop ax
ret


; Funcion para cambiar la posicion del cursor
; cursor_offset_screen = (y * 80) + x
; E:F = cursor_offset_screen
; ax = ?
; bx = x, y = bh-x, bl-y
.gotoxy:
	push ax
	push bx
	push dx

	; bh = x
	; bl = y
	mov byte [cursor_x], bh
	mov byte [cursor_y], bl

	xor ax, ax
	mov al, byte [cursor_y]
	mov bx, 80
	mul bx
	xor bx, bx
	mov bl, byte [cursor_x]
	add ax, bx
	mov word [cursor_offset_screen], ax


	; E:F = cursor_offset
	mov bx, word [cursor_offset_screen]
	call .vga_gotoxy

	;actualizamos el puntero de la memoria
	mov ax, word [cursor_offset_screen]
	mov bx, 2
	mul bx
	mov word [cursor_offset_memory], ax

	pop dx
	pop bx
	pop ax
ret

; funcion para manejar caracteres no imprimibles/especiales
.process_special_char:
	push es
	push di
	push ax
	push bx

	cmp al, 0x0A ;endl
	je .print_endl
	cmp al, 0x0D ;retorno de carro
	je .print_ret_carro

	.print_endl:
	mov bl, byte [cursor_y]
	inc bl
	mov bh, byte [cursor_x]
	call .gotoxy
	jmp .done_special_char

	.print_ret_carro:
	xor bh, bh
	mov bl, [cursor_y]
	call .gotoxy
	jmp .done_special_char

	;verificamos que el cursor este en 0, 0
	or bl, bh
	jz .done_special_char

	;verificamos que el cursor este al principio
	cmp bh, 0
	je .ret_car_y

	dec bh
	call .gotoxy
	mov bl, " "
	call .putchar
	mov bh, byte [cursor_x]
	mov bl, byte [cursor_y]
	dec bh
	call .gotoxy

	jmp .done_special_char
	;si el cursor esta en 0,y regresamos en 1y
	.ret_car_y:
	mov bl, byte [cursor_y]
	dec bl
	mov bh, byte [screen_char_len_x]
	call .gotoxy
	mov bl, " "
	call .putchar
	mov bl, byte [cursor_y]
	dec bl
	mov bh, byte [screen_char_len_x]
	call .gotoxy

	jmp .done_special_char


	.done_special_char:

	pop bx
	pop ax
	pop di
	pop es
ret

; Funcion para cambiar el color del texto vga
; ah = 0x03
; al color
.set_text_color:
    mov byte [text_color], al
ret

;------------------------------------------------

;################################################

;-----------------------------
;ENTRADA DE DATOS POR TECLADO
;-----------------------------

; funcion getchar
;funcion para obtener el codigo ascii de
; una teclapresionada
; ah = 0x06
; Retorna en el registro
;  al = codigo ascii de la tecla presionada
.getchar:
	push bx

	xor ax, ax
	xor bx, bx
	;verificamos que hay algo en el buffer
	;si no hay nada, esperamos
	;si hay algo devolvemos el valor del buffer en dl
	;head++ && 0x0F

	.wait_loop:

	cli
	mov al, byte [kb_buffer_head]
	mov bl, byte [kb_buffer_tail]
	cmp al, bl
	jne .return_char
	sti

	hlt
	jmp .wait_loop

	.return_char:
	cli
	mov al, byte [kb_buffer + bx]
	inc bl
	and bl, 0x0F
	mov byte [kb_buffer_tail], bl
	sti

	test al, 0x80
	jnz .wait_loop

	; al lo convertimos a ascii
	; el codigo ascii se retorna en al
	call .scancode_to_ascii

	pop bx
ret

;convertimos el scancode a ascii
; al = scancode
; return al = ascii
.scancode_to_ascii:
	push bx

	xor bh, bh
	mov bl, al
	mov al, byte [ascii_table + bx]

	pop bx
ret
