bits 16
org 0

cli
mov ax, 0x0AC0
mov ds, ax
mov ax, 0x0000
mov ss, ax
sti

mov sp, 0x9FFF

mov ah, 0x00
mov al, 0x03
int 0x10

mov si, msgSrhKernel
call .print_str

mov ax, 0x0900
mov es, ax
mov di, 0x0000
call .findFile

jmp $

;-----------

.findFile:
	mov cx, 11
	mov si, kernel_name
	push di

	.loopName:
		;repe cmpsb ;compara ds:si y es:di cx veces
		mov al, BYTE [ds:si]
		cmp al, BYTE [es:di]
		jne .notMatch
		inc si
		inc di
		loop .loopName

		pop di
		jmp .fileFound
		.notMatch:
		pop di
		add di, 32
		cmp di, 480
		jge .file_not_found
		jmp .findFile

.file_not_found:
    mov si, msgKernelNF
	call .print_str
	jmp $


;el kernel sera cargado en 0x1000:0x0000
.fileFound:
	mov ax, 0x0900
	mov es, ax
	add di, 0x001A ;ubicacion del primer cluster desde la entrada

	mov ax, WORD [es:di]
	mov WORD [cluster_actual], ax

	mov ax, 0x0000
	mov WORD [dir_offset], ax
	mov ax, 0x1000
	mov WORD [dir_segment], ax

	;bucle para encontrar el resto de cluster y cargarlos
	;fat cargado en 0x07E00
	.load_clusters:
		mov ax, WORD [cluster_actual]
		cmp ax, 0x0FF8 ;verificamos si ya se cargó completo el archivo
		jae .done_ld_clusters

		call .calc_LBA ;el resultado se guarda en ax
		;mov WORD [LBA], ax ;-de momento inservible
		call .calcular_chs
		mov bx, WORD [dir_segment]
		mov es, bx
		mov bx, WORD [dir_offset]
		call .readDisk ;se carga el primer cluster

		add WORD [dir_offset], 512
		jnc .not_carry
		inc WORD [dir_segment]
		.not_carry:

		;vamos a fat y buscamos el siguiente cluster
		mov di, 0x0000 ;nos ubicamos en fat, 0x07E00
		mov ax, 0x07E0
		mov es, ax
		;calculamos el offset en fat
		mov ax, WORD [cluster_actual]
		mov bx, 3
		mul bx
		mov bx, 2
		xor dx, dx
		div bx

		;leemos 16 bits desde FATstart + POS
		add di, ax

		mov ax, WORD [es:di]

		push ax

		mov ax, WORD [cluster_actual]
		and ax, 0x0001 ;verificamos si es par o impar
		cmp ax, 0x0000

		je .num_par

		;esto por si es impar
		pop ax
		shr ax, 4
		mov WORD [cluster_actual], ax
		jmp .next_step

		.num_par:
		pop ax
		and ax, 0x0FFF
		mov WORD [cluster_actual], ax

		.next_step:

		mov ax, WORD [cluster_actual]
		;add ax, 33
		call .putchar

		jmp .load_clusters
		.done_ld_clusters:

		cli
		mov ax, 0x1000
		mov ds, ax
		mov ax, 0x0000
		mov ss, ax
		mov sp, 0x9FFF
		sti
		jmp 0x1000:0x0000 ;saltamos al kernel

ret

.calc_LBA:
	sub ax, 2
	xor bx, bx
	mov bl, BYTE [SectorsPerCluster]
	mul bx
	xor bx, bx
	mov bl, BYTE [DataStart]
	add ax, bx
ret


.calcular_chs:
	push ax

	xor dx, dx
	mov bx, WORD [SectorsPerTrack]
	div bx
	inc dl
	mov BYTE [sector], dl

	mov bx, WORD [HeadCounts]
	xor dx, dx
	div bx

	mov BYTE [pista], al
	mov BYTE [cabeza], dl

	pop ax
ret


.readDisk:
	mov ah, 0x02
	mov al, 1 ;sectores a leer
	mov ch, BYTE [pista];0 ;track
	mov cl, BYTE [sector];2 ;numero de sector
	mov dh, BYTE [cabeza];1 ;cabeza
	mov dl, 0x00

	push ax
	push bx
	push cx
	push dx

	int 0x13

	pop dx
	pop cx
	pop bx
	pop ax
	jc .diskReadError
	ret

.diskReadError:
	push ax

	mov al, byte [DriveNumber]
	inc al
	mov byte [DriveNumber], al
	cmp al, 1

	pop ax
	jle .readDisk

	mov si, msgDiskReadError
	call .print_str
	jmp $


.print_str:
	mov al, [si]
	inc si
	or al, al
	jz .done
	call .putchar
	jmp .print_str
	.done:
		ret

.putchar:
	mov ah, 0x0e
	int 0x10
	ret

;msgBootStII db "Stage II", 0xa, 0xd, 0
msgSrhKernel db "Search KERNEL.BIN...", 0xa, 0xd, 0
msgKernelNF db "Kernel not found", 0xa, 0xd, 0
msgDiskReadError db "Error To Read Disk", 0xa, 0xd, 0

SectorsPerCluster db 1
SectorsPerFat dw 9
SectorsPerTrack dw 18
HeadCounts dw 2
DataStart db 33
DriveNumber db 0

cluster_actual dw 0
dir_offset dw 0
dir_segment dw 0

sector db 0
pista db 0
cabeza db 0

kernel_name db "KERNEL  BIN"

;debug
mov ax, 0xB800
mov ax, es
mov byte [ES:0], "Z"
mov byte [ES:0], 0x02
