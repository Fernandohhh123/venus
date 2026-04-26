;interruption vector table

; se llama al sistema con int 0x80

;Este archivo contiene informacion y funciones para
; modificar la ivt de la bios para usar funciones propias

;Funciones propias
; putchar
;

.set_ivt:
	push es
	push ax

	;--------------------------------------------
	; Interrupcion para el usuario
	xor ax, ax
	mov es, ax
	mov word [es:0x80*4], .syscall_dispatcher
	mov word [es:0x80*4+2], cs
	;----------------------------------


	;--------------------------------------------
	; keyboard handler
	xor ax, ax
	mov es, ax
	mov word [es:0x09*4], .keyboard_handler
	mov word [es:0x09*4+2], cs
	;----------------------------------

	pop ax
	pop es
ret
