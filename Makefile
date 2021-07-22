
ProjName=bootbf
QEMUOpts=-drive format=raw,file=$(ProjName).bin

.PHONY: build launch help
help:
	@echo "make <build|launch|launch-curses|deploy|clean|help>"

build:
	nasm -f bin $(ProjName).asm -o $(ProjName).bin

deploy: build
	dd if=/dev/zero of=filler bs=512 count=2879
	cat $(ProjName).bin filler > $(ProjName).img
	rm filler

launch-curses: build
	qemu-system-i386 $(QEMUOpts) -curses

launch: build
	qemu-system-i386 $(QEMUOpts)

clean:
	rm $(ProjName).bin $(ProjName).img
