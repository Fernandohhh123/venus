#!/bin/bash

# Default: Ensambla y copia los archivos a la imagen

# Full: Crea la imagen de un floppy de 1.44mb
#  formatea la imagen en fat12
#  ensalmbla los archivos y los copia a la imagen

# Debug: Hace casi lo mismo que Full
#  solo que agrega simbolos de depuracion para gdb

if [ "$1" == "debug" ]; then

	echo "creando carpetas"
	mkdir -p bin

	echo "Ensamblando"
	nasm -f bin src/kernel/kernel.s -o bin/kernel.bin
	nasm -f bin src/boot/bootStageTwo.s -o bin/bootstii.bin
	nasm -f bin src/boot/boot.s -o bin/boot.bin

	echo "Creando la imagen"
	dd if=/dev/zero of=venus.img bs=512 count=2880

	echo "Formateando la imagen"
	sudo mkfs.fat -F 12 venus.img

	echo "Grabando boot"
	#dd if=bin/bootFirstStage.bin of=venus.img bs=512 seek=0 conv=notrunc
	dd if=bin/boot.bin of=venus.img bs=512 seek=0 conv=notrunc

	#dd if=bin/bootSecondStage.bin of=venus.img bs=512 seek=34 conv=notrunc

	echo "copiando archivos"
	mcopy -i venus.img bin/kernel.bin ::KERNEL.BIN
	mcopy -i venus.img bin/bootstii.bin ::BOOTSTII.BIN

# Ensamblando version ELF para gdb

	mkdir -p debug

	#nasm -f elf32 -F dwarf -g src/kernel/kernel.s -o debug/kernel.o
	#nasm -f elf32 -F dwarf -g src/boot/bootStageTwo.s -o debug/bootstii.o
	nasm -f elf32 -dELF -F dwarf -g src/boot/boot.s -o debug/boot.o

	ld -m elf_i386 -Ttext 0x7C00 --oformat elf32-i386 debug/boot.o -o debug/boot.elf

	echo "Listo"

############################
	else
###########################

echo "creando carpetas"
mkdir -p bin

echo "Ensamblando"
nasm -f bin src/kernel/kernel.s -o bin/kernel.bin
nasm -f bin src/boot/bootStageTwo.s -o bin/bootstii.bin
nasm -f bin src/boot/boot.s -o bin/boot.bin

echo "Creando la imagen"
dd if=/dev/zero of=venus.img bs=512 count=2880

echo "Formateando la imagen"
sudo mkfs.fat -F 12 venus.img

echo "Grabando boot"
#dd if=bin/bootFirstStage.bin of=venus.img bs=512 seek=0 conv=notrunc
dd if=bin/boot.bin of=venus.img bs=512 seek=0 conv=notrunc

#dd if=bin/bootSecondStage.bin of=venus.img bs=512 seek=34 conv=notrunc

echo "copiando archivos"
mcopy -i venus.img bin/kernel.bin ::KERNEL.BIN
mcopy -i venus.img bin/bootstii.bin ::BOOTSTII.BIN

echo "Listo"

fi
