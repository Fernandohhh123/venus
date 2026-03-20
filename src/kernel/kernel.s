bits 16
org 0



cli
mov ax, 0x1000
mov ds, ax
mov ax, 0x1000
mov ss, ax
mov sp, 0xFFFF
sti

jmp start

;system info
OS_name db "venus", 0
OS_version db "0.1", 0
prompt db "> ", 0




start:
	call .init_video

	mov si, OS_name
	call .print_str

	mov al, "E"
	call .putchar

;--


;-------------------------
.main_loop:

	jmp .main_loop

%include "src/kernel/video.s"
%include "src/kernel/ivt.s"


msgEnterMainLoop db "Enter to main loop", 0

msgEndl db 0xa, 0xd, 0
