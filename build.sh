echo "Ensamblando"
#nasm -f bin src/boot/bootFirstStage.s -o bin/bootFirstStage.bin
#nasm -f bin src/boot/bootPtOne.s -o bin/bootSecondStage.bin
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
#mcopy -i venus.img bin/kernel.bin ::KERNEL.BIN
#dd if=bin/boot.bin of=venus.img bs=512 seek=0 conv=notrunc
echo "Listo"

#echo "Corriendo..."
#qemu-system-i386 -fda bin/boot.bin
