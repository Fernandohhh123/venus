;--------------------------------------------------------
; datos para el sistema
;system info
OS_name db "venus", 0
OS_version db "0.1", 0
char_endl db 0x0A, 0x0D, 0
msg_etapa_desarrollo db "alpha-experimental", 0x0a, 0xd, 0
msgEnterMainLoop db "Enter to main loop", 0x0A, 0x0D, 0

prompt db ">", 0
;--------------------------------------------------------

;--------------------------------------------------------
; datos usados para gestionar el video del sistema
; video data
text_color db 7 ;blanco
screen_char_len_x db 0 ;dato para saber cuantos caracteres caben en la pantalla en x
screen_char_len_y db 0 ;dato para saber cuantos caracteres caben en la pantalla en y
cursor_offset_memory dw 0x0000 ;posicion en memoria de video para saber donde escribir
cursor_offset_screen dw 0x0000 ;posicion del cursor dentro de la pantalla

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


;--------------------------------------------------------
;datos para gestionar las abstacciones de video
; posicion del cursor en un plano bidimencional
cursor_x db 0 ; posicion X del cursor en el monitor
cursor_y db 0 ; posicion Y del cursor en el monitor


;--------------------------------------------------------
;Datos para el buffer de teclado keyboard_handler
kb_buffer db 16 dup(0) ;reservamos 16 bytes iniciados en 0
kb_buffer_head db 0
kb_buffer_tail db 0


ascii_table:
	db '0'
	db 'E' ;esc
	db '1', '2', '3', '4' ,'5', '6', '7', '8', '9', '0'
	db '-', '='
	db 0x08 ; backspace
	db 'T' ; tab
	db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'
	db 'E' ; enter
	db 'C' ; ctl
	db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'"
	db "`"
	db 'S' ;shift left
	db '\'
	db 'z', 'x', 'c', 'v', 'b', 'n', 'm'
	db ','
	db '.'
	db '/'
	db 'S' ; shift right
	db 'P' ; print sc
	db 'A' ; alt
	db ' ' ; espacio
	db 'L' ; bloq mayus
	db '1' ; F1
	db '2' ; F2
	db '3' ; F3
	db '4' ; F4
	db '5' ; F5
	db '6' ; F6
	db '7' ; F7
	db '8' ; F8
	db '9' ; F9
	db '0' ; F10

	db '?' ;-----------
	db '?' ;-----------

	db '0' ; home
	db '0' ; flechita arriba
	db 'P' ; PgUp

	db '?' ;------------

	db '0' ; flechita izquierda

	db '?' ;------------

	db '0' ; flechita derecha

	db '?' ;-----------

	db '0' ; end
	db '0' ; flechita abajo
	db '0' ; PgDn
	db '0' ; insert

	db '0' ; delete
	db '1'
	db '2'
	db '3'
	db '0' ; F11
	db '0' ; F12
	db '4'
	db '5'
	db '0' ;super / mod / win
	db '7'
	db '8'
	db '9'
