.init_video:
	push es
	push di
	push ax

    mov al, 80
    mov byte [screen_char_len_x], al
    mov al, 25
    mov byte [screen_char_len_y], al

    mov al, 00000111b ;color blanco sobre fondo negro
    mov byte [text_color], al
	mov ah, 0x00

	mov word [cursor_offset_memory], 0x0000

	mov bx, 0x0000
	call .gotoxy

	pop ax
	pop di
	pop es

    ret

.set_text_atributes:
    mov byte [text_color], bl
    ret

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

	; verificamos si es un caracter especial --

	; si no lo es, lo imprimimos --

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
	mov bh, 0
	mov bl, byte [cursor_y]
	inc bl
	call .gotoxy
	.done_update_cursor:

	pop di
	pop es
	pop bx
	pop ax
ret

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

; ########################################

text_color db 7 ;blanco
screen_char_len_x db 0 ;dato para saber cuantos caracteres caben en la pantalla en x
screen_char_len_y db 0 ;dato para saber cuantos caracteres caben en la pantalla en y
cursor_offset_memory dw 0x0000 ;posicion en memoria de video para saber donde escribir
cursor_offset_screen dw 0x0000 ;posicion del cursor dentro de la pantalla

; abstracciones
cursor_x db 0 ; posicion X del cursor en el monitor
cursor_y db 0 ; posicion Y del cursor en el monitor


;-----------------------------------------
;.tabla_char_especiales:
;text colors
;text_color_blue db 1
;text_color_green db 2
;text_color_turquoise db 3
;text_color_red db 4
;text_color_pink db 5
;text_color_orange db 6
;text_color_white db 7
; text_color_gray db 8
; text_color_purple db 9
; text_color_lightGreen db 10
; text_color_lightTurquoise db 11


