.PHONY: all run debug clean os

all: rom.bin os

rom.bin: bios/bios.s bios/wozmon.s bios/basic.s
	vasm6502_oldstyle bios/bios.s -o rom.bin -Fbin -wdc02 -dotdir

os:
	$(MAKE) -C os

run_no_os: rom.bin
	toml-6502

run: rom.bin os
	toml-6502 config.toml NVRAM=os/os.img NVRAM_SIZE=17408

debug: rom.bin os
	toml-6502 -m config.toml NVRAM=os/os.img NVRAM_SIZE=17408

clean:
	rm *.bin
	$(MAKE) -C os clean