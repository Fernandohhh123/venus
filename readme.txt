
sistema operativo para 8086 modo real

caracteristicas:
- monotarea
- no tiene usuarios
- sistema de archivos usado fat12
- modo de video vga 80x25 a color
- sistema para floppy disk
- kernel monolitico

:)

### Como Compilar ###
se usa nasm para compilar este SO

- El stcript build.sh debe tener permisos de ejecucion
- El script creara una imagen llamada: venus.img
- Esta imagen solo se ha probado en qemu-system-i386
- Se corre como si estuviera en un floppy disk
