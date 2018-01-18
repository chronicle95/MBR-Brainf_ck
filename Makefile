all:
	nasm -f bin bootbf.asm -o bootbf.bin
	qemu-system-i386 -drive format=raw,file=bootbf.bin	
build:
	nasm -f bin bootbf.asm -o bootbf.bin
launch:
	qemu-system-i386 -drive format=raw,file=bootbf.bin
