.PHONY: core demos all run clean

rom.bin: bios.s wozmon.s basic.s
	vasm6502_oldstyle bios.s -o rom.bin -Fbin -wdc02 -dotdir

hello_world.woz: hello_world.s
	vasm6502_oldstyle hello_world.s -o hello_world.hex -Fihex -wdc02 -dotdir
	hex2woz hello_world.hex

core: rom.bin

demos: hello_world.woz

all: core demos

run: core
	toml-6502

clean:
	rm *.bin *.woz *.hex *.img