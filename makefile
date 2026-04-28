boot.bin: src/boot.s
	mkdir -p bin
	nasm -f bin src/boot.s -o bin/boot.bin

bootStageTwo.bin: src/bootStageTwo.s
	nasm -f bin src/bootStageTwo.s -o bin/bootStageTwo.s
