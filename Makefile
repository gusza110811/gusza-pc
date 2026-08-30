.PHONY: all run debug clean os demo

demos := hello_world

all: rom.bin osall.img

rom.bin: bios/bios.s bios/wozmon.s bios/basic.s
	vasm6502_oldstyle bios/bios.s -o rom.bin -Fbin -wdc02 -dotdir

osall.img: os demo
	cp os/os.img ./osall.img

	@for demo in $(demos); do \
		badfs osall.img import demo/$$demo $$demo; \
	done


os:
	$(MAKE) -C os

demo:
	$(MAKE) -C demo DEMOS=$(demos)

run_no_os: rom.bin
	toml-6502

run: all
	toml-6502 config.toml NVRAM=osall.img NVRAM_SIZE=17408

debug: all
	toml-6502 -m config.toml NVRAM=osall.img NVRAM_SIZE=17408

clean:
	rm -f *.bin *.img
	$(MAKE) -C os clean
	$(MAKE) -C demo clean DEMOS=$(demos)