CC=m68k-atari-mint-gcc
CFLAGS=-s -nostdlib

keyb_inj.prg: main.S cookie.S
	$(CC) $(CFLAGS) -o $@ $+

testkinj.prg: test.S cookie.S
	$(CC) $(CFLAGS) -o $@ $+

# make runtest HATARI=path/to/hatari TOSIMG=path/to/tos
runtest: keyb_inj.prg testkinj.prg
	mkdir -p AUTO
	cp keyb_inj.prg testkinj.prg AUTO
	$(HATARI) -d . -t $(TOSIMG) --bios-intercept on --midi-in nul --midi-out con --log-level fatal --alert-level fatal --fast-forward on --fast-boot on

.PHONY: clean
clean:
	rm -rf keyb_inj.prg testkinj.prg AUTO
