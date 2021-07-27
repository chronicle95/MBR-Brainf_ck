## About

This is a simple [Brainf\*ck](https://en.wikipedia.org/wiki/Brainfuck) interpreter made for playing around with X86 assembly. It fits completely into the 512 byte boot sector.

Command line interface supports typing in up to 10 individual programs (1 KiB each).

All of them share the same piece of memory of around 22 KiB (minus some padding for stack allocation on top).

## Build

You will need NASM to assemble this.

Run `make build` to get the binary file: bootbf.bin.

## Deploy/Test

If you have QEMU x86 installed, you can just do `make launch`.

It will both assemble and execute the environment in the VM.

To install on a physical device, like USB flash drive, you can use dd:

`# dd if=bootbf.bin of=/dev/sdX bs=512`

In my case to make it work I also needed to set the boot flag using `fdisk`.
Of course, the BIOS should support the legacy boot mode.

## Usage

The interpreter itself does supply a bit of help on startup.

### Edit program

Press key 0 to 9 to select current program. Program's text is going to be displayed on the screen.

Press `e` to type in the code. When you are done entering the program, press `Enter` key.

Use backspace to correct the code.

If you issue the `e` command again, it will overwrite the previous code (in the selected program only).

When the screen becomes too polluted, use `c` command to clear it. The program will be defauled to 0.

### Execute

Use `r` to run the program.

It has no boundaries checks.

Memory constraints are: 1 KiB for code and up to 22KiB for data.

The memory may initially contain garbage so keep this in mind when designing BF programs (it is not cleaned between runs by design).

Halt the program at any point by pressing `Escape`.

*Note: any user input during the execution can not be corrected with Backspace, i.e. is not buffered.*

When back at the prompt, the selected program is 0 by default.

### Dialect differences

This dialect of the language has a couple of extra commands, which are not present in standard BF.

It also has not one, but two data pointers, which initially both point at the leftmost memory cell.

- `%` - swap the pointers. This operator switches the active pointer, allowing for simultaneous processing of two separate memory locations.

- `^` - copy cell value to the second pointer location. This allows for working on volatile memory without altering original value or other example would be the ease of character string processing.

- `0`..`9` - run another program as subroutine. Another program is called, but all the state (except for IP) remains. It is possible to call as deeply into stack as there is memory available, but all of the subroutines share the same two pointers, same memory etc. When the subroutine is done executing, the IP will go back to the next instruction.
