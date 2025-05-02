boot.img: boot.asm
	nasm -f bin -o boot.img boot.asm
all: boot.img
	.phony
	