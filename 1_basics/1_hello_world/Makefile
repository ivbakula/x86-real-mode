SRC = $(wildcard *.asm)
TGT = boot.bin

all:
	nasm -f bin $(SRC) -o $(TGT) 

test:
	qemu-system-i386 -fda $(TGT) 

clean:
	rm $(TGT)
