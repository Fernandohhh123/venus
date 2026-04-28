;------------------------------------------------
;Este archivo contiene funciones para
; manejar el sistema
;------------------------------------------------

.init_video:
	push es
	push di
	push ax
	push bx

    mov al, 79
    mov byte [screen_char_len_x], al
    mov al, 24
    mov byte [screen_char_len_y], al

    mov al, 00000111b ;color blanco sobre fondo negro
    mov byte [text_color], al
	mov ah, 0x00

	mov word [cursor_offset_memory], 0x0000

	; limpiamos la pantalla
	call .clear_screen

	mov bx, 0x0000
	call .gotoxy

	pop bx
	pop ax
	pop di
	pop es

    ret
