.PHONY: all

all: os.img

boot.bin: boot.s
	vasm6502_oldstyle boot.s -o boot.bin -Fbin -wdc02 -dotdir

kernel.bin: kernel.s
	vasm6502_oldstyle kernel.s -o kernel.bin -Fbin -wdc02 -dotdir

os.img: boot.bin kernel.bin
	cp boot.bin os.img
	truncate -s 17K os.img
	badfs os.img import kernel.bin KERNEL

clean:
	rm -f *.img *.bin
