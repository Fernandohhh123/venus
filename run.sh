#!/bin/bash

if [ "$1" == "debug" ]; then

	qemu-system-i386 \
	-drive file=venus.img,format=raw,if=floppy \
	-m 1M \
	-vga std \
	-s -S

else

	qemu-system-i386 \
	-drive file=venus.img,format=raw,if=floppy \
	-m 1M -vga std

fi
