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

	mov bl, 11000111b
	call .set_text_color
	mov bx, msg_etapa_desarrollo
	call .print_str

	; cambiamos el color a blanco
	mov bl, 00000111b
	call .set_text_color

	sti ;<<<<<<
	jmp .main_loop

;-------------------------
;-------------------------

.main_loop:

	call .getchar
	mov bl, dl
	call .putchar

	jmp .main_loop


;------------------------------------------------
; Aqui se procesan las llamadas al sistema
;------------------------------------------------
.syscall_dispatcher:
	push ax
	push bx
	push cx
	push es
	push di

	; putchar
	cmp al, 0x01
	je .sys_putchar



	.sys_putchar:
	call .putchar
	jmp .done_syscall_dispatcher

	.done_syscall_dispatcher:
	pop di
	pop es
	pop cx
	pop bx
	pop ax
ret

%include "src/kernel/stdio.s"
%include "src/kernel/video.s"
%include "src/kernel/ivt.s"
%include "src/kernel/drivers/vga_driver.s"
%include "src/kernel/drivers/keyboard_driver.s"
