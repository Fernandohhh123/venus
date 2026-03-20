bits 16
org 0

jmp short start ;salto a la ejecucion del bootloader
nop ;instruccion para poder ajustar la tabla bpb, da lo mismo poner un db 0

;tabla BPB para fat12
OEMName db "VENUSO.1"
BytesPerSector dw 512
SectorsPerCluster db 1
ReservedSectorsCounter dw 1
FATcount db 2
DirEntires dw 224
TotalSectors dw 2880 ;total sectores en un floppy, 1.44 mb
MediaDescriptor db 0xF0
SectorsPerFat dw 9
SectorsPerTrack dw 18
HeadCounts dw 2
HiddenSectors dd 0

DriveNumber db 0
Reserved1 db 1
BootSignature db 0x29
VolumeID dd 77
VolumeLabel db "Venus      ";debe medir 11 bytes
FSType db "FAT12   " ;debe medir 8 bytes

;------------------------------------------------

;StartFAT = sectores reservados

;inicio de root
;RootDirStart = ReservedSectorsCounter + (FATcount * SectorsPerFat)
RootDirStart db 19

;inicio del area de datos o cuantos sectores ocupa root
;RootDirSectors = ((DirEntires * 32) + BytesPerSector - 1) / BytesPerSector
;DataStart = RootDirStart + RootDirSectors - 1
;con esto, tenemos el comienzo del cluster 2
RootDirSectors db 14
RootEnd db 32
DataStart db 33
FATstart db 1
RootSectorActual db 0

sector db 0
pista db 0
cabeza db 0

;espacios en memoria para gestionar la carga de datos
dir_offset dw 0
dir_segment dw 0
cluster_actual dw 0
LBA dw 0

file_name db "BOOTSTIIBIN"
;kernel_name db "KERNEL  BIN"

start:

	cli
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ax, 0x0000
    mov ss, ax
    sti

    mov sp, 0x7bff

	;cargamos fat1 en 0x07E00 y termina en 0x08FFF
	;leemos a partir del sector 1
	mov ah, 2
	mov al, 9 ;cargaremos 9 sectores
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, [DriveNumber]
	xor bx, bx
	mov es, bx
	mov bx, 0x7E00
	int 0x13
	jc .diskReadError

	;cargamos root en 0x09000 hasta 0x0ABFF
	;leemos a partir del sector 19
	mov ah, 2
	mov al, 14 ;cargaremos 14 sectores
	mov ch, 0 ;pista
	mov cl, 2 ;numero de sector
	mov dh, 1 ;cabeza
	mov dl, [DriveNumber]
	xor bx, bx
	mov es, bx
	mov bx, 0x9000
	int 0x13
	jc .diskReadError

	mov ax, 0x0900
	mov es, ax
	mov di, 0x0000
	call .findFile

	call .fileFound

	jmp 0x0000:0xAC00 ;vamos al stgeII
;----End start------

.findFile:
	mov cx, 11
	mov si, file_name
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
		ret
		.notMatch:
		pop di
		add di, 32
		cmp di, 480
		jge .file_not_found
		jmp .findFile
;


.file_not_found:
	mov si, msgFileNotFound
	call .print_str
	jmp $

;aqui cargamos los clusters del st2
.fileFound:
	mov ax, 0x0900
	mov es, ax
	add di, 0x001A ;ubicacion del primer cluster desde la entrada

	mov ax, WORD [es:di]
	mov WORD [cluster_actual], ax

	mov ax, 0xAc00
	mov WORD [dir_offset], ax
	mov ax, 0x0000
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

;calcular CHS
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

;FIN de CHS

.readDisk:
	mov ah, 0x02
	mov al, 1 ;sectores a leer
	mov ch, BYTE [pista];0 ;track
	mov cl, BYTE [sector];2 ;numero de sector
	mov dh, BYTE [cabeza];1 ;cabeza
	mov dl, [DriveNumber]

	int 0x13

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
	mov al, BYTE [si]
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

msgDiskReadError db "ERD", 0xa, 0xd, 0
msgFileNotFound db "FNF", 0xA, 0xD, 0

times 510 - ($ - $$) db 0
db 0x55
db 0xAA
