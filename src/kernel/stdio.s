
;------------------------------------------------
;seccion para manejar flujo de salida de datos
;------------------------------------------------

; Funcion para limpiar la consola
;ax = ?
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
; ax ?
; bx = puntero al string, debe terminar con 0
.print_str:
	push es
	push di
	push ax

	mov di, bx

	; es:di
	.loop_print:

	mov bl, [es:di]
	inc di
	or bl, bl
	jz .done
	call .putchar
	jmp .loop_print
	.done:

	pop ax
	pop di
	pop es
ret

; Funcion para poner un caracter en la posicion actual del cursor
; ax = ?
; bl = ascii
.putchar:
	push ax
	push bx
	push es
	push di

	mov bh, byte [text_color]

	mov di, 0xb800
	mov es, di

	mov di, word [cursor_offset_memory]

	;## verificamos si es un caracter especial ----
	cmp bl, 0x20
	jg .print_n_char
	je .print_n_char ;si es 0x20 es un espacio
	call .process_special_char
	jmp .done_putchar

	;## si no lo es, lo imprimimos -------------


	.print_n_char: ; imprimimos un char normal
	mov byte [es:di], bl
	inc di
	mov byte [es:di], bh
	inc di
	mov word [cursor_offset_memory], di

	; actualizamos la posicion del cursor
	mov al, byte [cursor_x]
	mov ah, byte [screen_char_len_x]

	cmp al, ah
	jg .print_new_line

	mov bh, byte [cursor_x]
	inc bh
	mov bl, byte [cursor_y]
	call .gotoxy

	jmp .done_update_cursor
	.print_new_line:
	xor bh, bh
	mov bl, byte [cursor_y]
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

	cmp bl, 0x0A ;endl
	je .print_endl
	cmp bl, 0x0D ;retorno de carro
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

	.done_special_char:

	pop bx
	pop ax
	pop di
	pop es
ret
;------------------------------------------------


;------------------------------------------------
; FLUJO DE DATOS DE ENTRADA POR EL TECLADO
;------------------------------------------------
.keyboard_handler:
	push ax
	push bx

	in al, 0x60 ;leemos scancode

	test al, 0x80
	jnz .fin_kb_handler

	mov bl, al
	add bl, '0'
	call .putchar

	.fin_kb_handler:
	mov al, 0x20
	out 0x20, al

	pop bx
	pop ax
iret
