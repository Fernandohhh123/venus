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

	sti ;<<<<<<
	jmp .main_loop

;-------------------------
;-------------------------

.main_loop:

	call .start_terminal

	jmp .main_loop


;------------------------------------------------
; Aqui se procesan las llamadas al sistema
;------------------------------------------------
.syscall_dispatcher:
	push bx
	push cx
	push dx
	push si
	push es
	push ds
	push di

	; putchar
	cmp ah, 0x01
	je .sys_putchar
	cmp ah, 0x02
	je .sys_print_str
	cmp ah, 0x03
	je .sys_set_text_color
	cmp ah, 0x06
	je .sys_getchar

	jmp .done_syscall_dispatcher

	.sys_putchar:
	call .putchar
	jmp .done_syscall_dispatcher

	.sys_print_str:
	call .print_str
	jmp .done_syscall_dispatcher

	.sys_getchar:
	call .getchar
	jmp .done_syscall_dispatcher

	.sys_set_text_color:
	call .set_text_color
	jmp .done_syscall_dispatcher

	.done_syscall_dispatcher:


	pop di
	pop ds
	pop es
	pop si
	pop dx
	pop cx
	pop bx
iret

%include "src/kernel/stdio.s"
%include "src/kernel/video.s"
%include "src/kernel/ivt.s"
%include "src/kernel/drivers/vga_driver.s"
%include "src/kernel/drivers/keyboard_driver.s"
%include "programs/terminal.s"
