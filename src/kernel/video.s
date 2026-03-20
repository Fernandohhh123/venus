.init_video:
    mov ax, 3
    int 0x10

    mov ax, 80
    mov [screen_char_len_x], ax
    mov ax, 25
    mov [screen_char_len_y], ax

    mov al, 7
    mov byte [text_color], al

    ret

.set_text_atributes:
    mov byte [text_color], al
    ret


.syscall_dispatcher:

ret

.print_str:

ret

.putchar:

ret


text_color db 7 <blanco
screen_char_len_x dw 0 ;dato para saber cuantos caracteres caben en la pantalla en x
screen_char_len_y dw 0 ;dato para saber cuantos caracteres caben en la pantalla en y
last_pos_cursor dw 0

.tabla_char_especiales:



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


