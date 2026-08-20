.PHONY: core all run

rom.bin: wozmon.s basic.s
	vasm6502_oldstyle wozmon.s -o rom.bin -Fbin -wdc02 -dotdir

hello_world.woz: hello_world.s
	vasm6502_oldstyle hello_world.s -o hello_world.hex -Fihex -wdc02 -dotdir
	hex2woz hello_world.hex

core: rom.bin

all: core hello_world.woz

run: all
	toml-6502