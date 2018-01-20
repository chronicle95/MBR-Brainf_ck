## Build

You will need NASM to assemble this.

Run `make build` to get the binary file: bootbf.bin.

## Deploy

If you have QEMU x86 installed, you can just run `make`.

It will both assemble and execute the program in VM.

To install on a physical device, like USB flash drive, you can use dd:

`# dd if=bootbf.bin of=/dev/sdX bs=512`

In my case to make it work I also needed to set the boot flag using `fdisk`.

## Usage

The interpreter itself does supply a bit of help on startup.

### Edit

Press `e` to type in the code. When you are done entering the program, press `Enter` key.

Use backspace to correct the code.

If you issue the `e` command again, it will overwrite the previous code.

### Execute

Use `r` to run the program.

It has no boundaries checks.

Memory constraints are: 4K for code and ~28K for program.

The memory may initially contain garbage so keep this in mind when designing BF programs.

Halt the program by pressing `Escape`.
