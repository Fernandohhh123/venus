;bootloader en fat12 para x86 modo real

bits 16
org 0x7c00

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
RootDirStart dw 0

;inicio del area de datos o cuantos sectores ocupa root
;RootDirSectors = ((DirEntires * 32) + BytesPerSector - 1) / BytesPerSector
;DataStart = RootDirStart + RootDirSectors - 1
;con esto, tenemos el comienzo del cluster 2
RootDirSectors dw 0
RootEnd dw 0
DataStart dw 0
RootSectorActual dw 0

kernel_name db "BOOTSTIIBIN"
;kernel_name db "KERNEL  BIN"

;estas variables son para calcular lba -> chs al leer el disco
cilindro dw 0
cabeza dw 0
sector dw 0

;esto sera de ayuda para encontrar los clusteres de el archivo que busquemos
clusterInicial dw 0
fatOffsetAux dw 0
fat_offset dw 0
fat_sector dw 0

FAT_Start db 0

;----------------------------------------------------


start:
	;mov ah, 0x0e
	;mov al, "F"
	;int 0x10

	;incializamos la pila
	cli
	mov ax, 0x0000
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	sti

	;calculamos el comienzo de root
	mov ax, [FATcount]
	mov bx, [SectorsPerFat]
	mul bx
	mov bx, [ReservedSectorsCounter]
	add ax, bx
	mov [RootDirStart], ax
	mov [RootSectorActual], ax
	;root comenzaria en el sector 19

	;calculamos los sectores que ocupa root
	;RootDirSectors = ((DirEntires * 32) + BytesPerSector - 1) / BytesPerSector
	mov ax, [DirEntires]
	mov bx, 32 ;numero de entradas
	mul bx ;7168
	mov bx, [BytesPerSector]
	dec bx ;511
	add ax, bx ;7679
	mov bx, [BytesPerSector]
	xor dx, dx
	div bx
	mov [RootDirSectors], ax
	;root ocuparia 14 sectores

	;calculamos el final de root
	mov ax, [RootDirSectors] ;19
	sub ax, 1 ;18
	add ax, [RootDirStart]
	mov [RootEnd], ax
	;32

	;calculamos el comienzo de los datos
	mov ax, [RootDirStart]
	add ax, [RootDirSectors]
	mov [DataStart], ax
	;33

	mov al, [ReservedSectorsCounter]
	mov [FAT_Start], al

	;escribimos un mensaje para el usuario
	;mov si, msgDebug
	;call .print_str

	call .read_root

    ;jmp $

;-------------------------------------------------

.read_root:
	;RootStart 19
	;RootSecotrs 15
	;datos se cargaran en 0x8000

	;lba -> chs
	;cilindro = sector_number / (sectors_per_track * heads)
	;head = (sector_number / sectors_per_track) % heads
	;sector = (sector_number % sector_per_track) + 1
	;para el residuo a-(b*parteEnteraResultado)

	call .calcularCHS

	xor ax, ax
	mov es, ax
	mov ax, ds
	mov bx, 0x8000
	call .read_disk

	;buscamos el kernel
	;mov al, "E"
	;call .putchar

	push ds
	push es
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov di, 0x8000
	.parserRootLoop:
		mov si, kernel_name
		mov al, [di]
		or al, al
		jz .doneReadRoot

		cmp al, 0xe5
		je .siguienteEntrada

		call .find_kernel

		.siguienteEntrada:
		
		add di, 32
		jmp .parserRootLoop

		.doneReadRoot:
		mov ax, [RootSectorActual]
		inc ax
		mov [RootSectorActual], ax
		pop ds
		pop es
		jmp .read_root
	
	ret

.calcularCHS:

	call .calcularSector
	call .calcularCabeza
	call .calcularCilindro
	
	ret

.calcularCilindro:
	;cilindro = sector_number / (sectors_per_track * heads)

	;push ax
	push bx
	;push dx

	xor dx, dx
	mov ax, [SectorsPerTrack] ;18
	mov bx, [HeadCounts] ;2
	mul bx ;36
	div WORD [RootSectorActual] ;19
	;div bx ;ax/bx
	mov [cilindro], ax

	;pop dx
	pop bx
	;pop ax

	ret

.calcularCabeza:
	;head = (sector_number / sectors_per_track) % heads
	;push ax
	push bx
	;push dx

	xor dx, dx
	xor ax, ax
	xor bx, bx
	mov al, [RootSectorActual]
	mov bl, [SectorsPerTrack]
	div bl
	mov bl, [HeadCounts]
	xor ah, ah
	div bl
	mov [cabeza], ah
	;mov al, [cabeza]

	;pop dx
	pop bx
	;pop ax

	ret

.calcularSector:
	;sector = (sector_number % sector_per_track) + 1
	;push ax
	push bx
	;push dx

	xor ax, ax
	xor bx, bx
	xor dx, dx

	mov al, [RootSectorActual] ;19
	mov bl, [SectorsPerTrack] ;18
	div bl
	add ah, 1
	mov [sector], ah
	;mov al, [sector]

	;pop dx
	pop bx
	;pop ax

	ret

.read_disk:

	;push ds
	push es
	;push ax
	push bx
	;push cx
	;push dx
	
	mov ah, 2 ;arguento de lectura de disco
	mov al, 1 ;numero de sectores a leer
	mov ch, [cilindro] ;pista/cilindro
	mov cl, [sector] ;numero de sector
	and cl, 00111111b
	mov dh, [cabeza] ;cabeza
	mov dl, [DriveNumber] ;driver
	int 0x13
	jc .diskErrorRead

	;pop dx
	;pop cx
	pop bx
	;pop ax
	pop es
	ret

.diskErrorRead:
	mov si, msgErrorReadDisk
	call .print_str
	jmp $

.find_kernel:

	push di

	mov cx, 11
	mov si, kernel_name

	.loop_name:
		mov al, [di]
		cmp al, [si]
		jne .not_match
		inc si
		inc di
		loop .loop_name

		;--------------
	pop di

	jmp .kernelFound

	.not_match:
	mov si, msgKernelNotFound
	call .print_str

	pop di
ret


.kernelFound:
	;mov al, "Z"
	;call .putchar

	;buscamos el primer cluster del kernel, debem de los bytes 26 y 27 de la entrada
	; contando desde 0

	;el kernel sera cargado a 0x1000:0x0000

	;FATofset = cluster + (cluster / 2)
	;byte dentro de fat en donde esta el cluster, falta convertirlo a sector fisico

	;vamos a sacar el sector a leer y el ofset respecto al sector
	;FAT_sector = FAT_start + (FAToffset / bytesPerSector)
	;FAT_index = FATOffset % bytesPerSector

	mov ax, [di + ENTRY_CLUSTER] ;vamos al primer cluster

	;convertir cluser a sector de datos
	;FirstDataSector = ReservedSectors + (Cluster - 2) * SectorsPerCluster

	;calculamos el sector

	;sector = DataStart + (cluster - 2)
	call .clusterToSector
	
	
	call .calcularCHS

	;mov ax, 1
    ;mov [cabeza], ax
    ;mov ax, 0
    ;mov [cilindro], ax
    ;mov ax, 16
    ;mov [sector], ax

	;ofset de fat al cluster
	;offsetaux = cluster + (cluster/2)
	mov ax, [di + ENTRY_CLUSTER]
	push ax
	xor dx, dx
	mov bx, 2
	div bx
	pop bx
	add ax, bx
	mov [fatOffsetAux], ax
	add ax, 40
	call .putchar



	mov bx, 0x0000
	mov ax, 0x1000
	mov es, ax

    call .read_disk

    ;mov ax, 0x1000
    ;mov ds, ax
    ;mov es, ax
    ;xor ax, ax
    ;mov di, ax

    ;mov cx, 512
    ;.loop:
    ;    mov al, [di]
     ;   call .putchar
      ;  inc di
       ; loop .loop

    jmp 0x1000:0x0000

	jmp $

.clusterToSector:
	;sector = DataStart + (cluster - 2)
	sub ax, 2
	mov bx, [DataStart]
	add ax, bx
	mov [RootSectorActual], ax
	ret

.findClusters:
	mov bx, 0x0000
	mov ax, 0x1000
	mov es, ax

    call .read_disk
	ret

.FirstDataSector:
	;FirstDataSector = ReservedSectors + (Cluster - 2) * SectorsPerCluster
	

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


;-----------------------------------------------

ENTRY_NAME equ 0x0B
ENTRY_CLUSTER equ 0x1A

;msgKernelNotFound db "Kernel no encontrado", 0xa, 0xd, 0
;msg db "Cargando el kernel", 0x0A, 0x0D, 0
;msgReadDisk db "Leyendo disco", 0x0A, 0x0D, 0
;msgDebug db "D",0xa, 0xd, 0
msgErrorReadDisk db "ERD",0xa, 0xd, 0
msgKernelNotFound db "KNF", 0xa, 0xd, 0

times 510 - ($ - $$) db 0
db 0x55
db 0xAA
