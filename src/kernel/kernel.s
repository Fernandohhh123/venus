; Este archivo es el principal del kernel,
; contiene la entrada principal al kernel, el
; loop principal, el manejo de las llamadas
; al sistema, y se incluyen todos los archivos
; relacionados con el kernel

; Funciones que contiene este archivo:
; kstart:
; .main_loop:
; .syscall_dispatcher:

; #######################################

bits 16
org 0

;-----------------
; Setup de kernel
;-----------------
    cli
    mov     ax, 0x1000
    mov     ds, ax
    mov     ax, 0x1000
    mov     es, ax
    mov     ax, 0x3000
    mov     ss, ax
    mov     sp, 0xFFFF
    sti

    jmp kstart

%include "src/kernel/data.s"

;---------------------
; Comienzo del kernel
;---------------------
kstart:
    cli

    call    .set_ivt
    call    .init_video

    mov     ah, 0x03
    mov     al, 01010000b
    call    .set_text_color

    mov     ah, 0x02
    mov     bx, OS_name
    call    .print_str

    mov     ah, 0x03
    mov     al, 00000000b
    call    .set_text_color

    mov     al, " "
    mov     ah, 0x01
    call    .putchar

    mov     ah, 0x03
    mov     al, 11000000b
    call    .set_text_color

    mov     ah, 0x02
    mov     bx, msg_etapa_desarrollo
    call    .print_str

    mov     ah, 0x03
    mov     al, 00000111b
    call    .set_text_color

    sti
    jmp     .main_loop

;---------------------------
; Loop principal del kernel
;---------------------------
.main_loop:

	call    .start_terminal

	jmp     .main_loop


;------------------------------------------
; Aqui se procesan las llamadas al sistema
;------------------------------------------
.syscall_dispatcher:
    push    bx
    push    cx
    push    dx
    push    si
    push    es
    push    ds
    push    di

    cmp     ah, 0x01
    je      .sys_putchar
    cmp     ah, 0x02
    je      .sys_print_str
    cmp     ah, 0x03
    je      .sys_set_text_color
    cmp     ah, 0x05
    je      .sys_clear_screen
    cmp     ah, 0x06
    je      .sys_getchar

    jmp     .done_syscall_dispatcher

.sys_putchar:
    call    .putchar
    jmp     .done_syscall_dispatcher

.sys_print_str:
    call    .print_str
    jmp     .done_syscall_dispatcher

.sys_set_text_color:
    call    .set_text_color
    jmp     .done_syscall_dispatcher

.sys_clear_screen:
    call    .clear_screen
    jmp     .done_syscall_dispatcher

    .sys_getchar:
    call    .getchar
    jmp     .done_syscall_dispatcher

.done_syscall_dispatcher:

    pop     di
    pop     ds
    pop     es
    pop     si
    pop     dx
    pop     cx
    pop     bx
iret

;--------------------------------------------
; Inclusion de todos los archivos del kernel
;--------------------------------------------
%include "src/kernel/stdio.s"
%include "src/kernel/video.s"
%include "src/kernel/ivt.s"
%include "src/kernel/drivers/vga_driver.s"
%include "src/kernel/drivers/keyboard_driver.s"
%include "programs/shell.s"
