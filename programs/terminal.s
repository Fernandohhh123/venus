;Este archivo contiene el programa de terminal
; para que el usuario interactue con el sistema

.start_terminal:
	; limpiamos la consola
	;mov ah, 0x05
	;int 0x80

	;color del prompt
	mov ah, 0x03
	mov al, 00000111b
	int 0x80

	mov ah, 0x02
	mov bx, terminal_endl
	int 0x80

	mov ah, 0x02
	mov bx, prompt
	int 0x80

	; cambiamos el color del texto
	mov ah, 0x03
	mov al, 00000111b
	int 0x80

	jmp .terminal_loop
ret

;################################
.terminal_loop:

	;getchar
	mov ah, 0x06
	int 0x80

	cmp al, 0x00
	je .terminal_loop

	;comprobamos backspace
	cmp al, 0x08
	je .call_back_space

	;comprobamos el salto de linea
	cmp al, 0x0A
	je .call_process_argument

	;metemos el caracter al buffer
	.normal_char:
	call .add_char_to_buffer
	jmp .terminal_loop


	.call_process_argument:
	call .process_argument
	jmp .terminal_loop

	.call_back_space:
	call .backspace

	jmp .terminal_loop
;###############################

;el char esta en AL
.add_char_to_buffer:
	push bx
	push es

	mov bx, ds
	mov es, bx

	xor bx, bx
	mov bl, byte [terminal_buffer_len]

	;comprobamos que el buffer este lleno
	cmp bl, 64d
	je .buffer_full

	mov byte [command_buffer + bx], al
	inc bl
	mov byte [terminal_buffer_len], bl

	mov ah, 0x01
	int 0x80

	.buffer_full:

	pop es
	pop bx
ret

.backspace:
	push ax
	push bx

	;comprobamos que haya algo en el buffer
	mov bl, byte [terminal_buffer_len]
	cmp bl, 0x00
	je .end_backspace

	dec bl
	mov byte [terminal_buffer_len], bl

	;imprimimos el back
	mov ah, 0x01
	mov al, 0x08
	int 0x80

	mov al, " "
	int 0x80

	mov al, 0x08
	int 0x80

	.end_backspace:

	pop bx
	pop ax
ret

;input
.process_argument:
	push ax
	push bx
	push cx
	push si
	push di
	push ds
	push es

	mov ax, ds
	mov es, ax

	;parser comando
	mov si, command_poweroff
	mov di, command_buffer
	.loop_parser:
	mov al, byte [es:di]
	cmp al, [ds:si]

	;comando poweroff

	jmp .end_process_argument


	.end_process_argument:

	; ponemos el puntero del buffer en 0
	mov al, byte [terminal_buffer_len]
	xor al, al
	mov byte [terminal_buffer_len], al

	mov ah, 0x02
	mov bx, terminal_endl
	int 0x80

	mov bx, prompt
	int 0x80

	pop es
	pop ds
	pop di
	pop si
	pop cx
	pop bx
	pop ax
ret

terminal_buffer_len db 0 ;puntero del buffer
command_buffer db 64d dup(0) ;bytes reservados para el buffer
prompt db ">", 0x00
prompt_len equ $ - prompt ;longitud del prompt
terminal_cursor_pos dw 0x0000 ;posicion del cursor en la terminal
terminal_endl db 0x0A, 0x0D, 0x00
command_poweroff db "poweroff"
command_clear db "clear"
