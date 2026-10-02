.PHONY: all

all: $(DEMOS)

$(DEMOS): $(foreach i, $(DEMOS), $(i).s)
	vasm6502_oldstyle $@.s -o $@ -Fbin -wdc02 -dotdir

clean:
	rm -f $(DEMOS)