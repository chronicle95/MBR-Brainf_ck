
ProjName=bootbf
QEMUOpts=-drive format=raw,file=$(ProjName).bin -curses

all: build launch

build:
	nasm -f bin $(ProjName).asm -o $(ProjName).bin

launch:
	qemu-system-i386 $(QEMUOpts)

clean:
	rm $(ProjName).bin
