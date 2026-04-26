bits 16
org 0

cli
mov ax, 0x1000
mov ds, ax
mov ax, 0x1000
mov es, ax
mov ax, 0x3000
mov ss, ax
mov sp, 0xFFFF
sti

jmp start

%include "src/kernel/data.s"

start:
	cli

	call .set_ivt

	call .init_video

	mov bl, 00000111b
	call .set_text_color

	;mov bl, 00000010b
	call .set_text_color
	mov bx, msgEnterMainLoop
	;call .print_str

	mov bl, 01010000b ;magenta
	call .set_text_color
	mov bx, OS_name
	call .print_str
	mov bl, " "
	call .putchar
	mov bx, OS_version
	call .print_str


	mov bl, 00000000b
	call .set_text_color
	mov bl, " "
	call .putchar

	mov bl, 01000000b
	call .set_text_color
	mov bx, msg_etapa_desarrollo
	call .print_str

	mov bl, 00000111b
	call .set_text_color

	sti ;<<<<<<
	jmp .main_loop

;-------------------------
;-------------------------

.main_loop:

	hlt
	;esperar interrupcion
	;leer teclado
	;procesar tecla presionada
	;ejecutar instruccion
	;loop

	jmp .main_loop

.syscall_dispatcher:

ret

%include "src/kernel/stdio.s"
%include "src/kernel/video.s"
%include "src/kernel/ivt.s"
