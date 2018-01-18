# Build
You will need NASM to assemble this.
Run `make build` to get the binary file: bootbf.bin.
If you have QEMU x86 installed, you can just run `make`.
It will both assemble and execute the program in VM.

# Usage
The interpreter itself does supply a bit of help on startup.
## Edit
Press `e` to type in the code. When you are done entering the program, press `Enter` key.
If you issue the `e` command again, it will overwrite the previous code.
## Execute
Use `r` to run the program.
It has no boundaries checks so virtually 64k of memory is available.
The memory may initially contain garbage so keep this in mind when designing BF programs.
At the moment if the program stucks in an infinite loop the only way to break the execution is to reboot the PC.
