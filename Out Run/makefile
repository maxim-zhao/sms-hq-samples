WLAZ80 = wla-z80
WLALINK = wlalink
PCMENC = pcmenc
FLIPS = flips

# The ROM filenames
ORIGINAL = outrun.sms
PATCHED = outrun-arcade-voices.sms
SOURCE = $(PATCHED:.sms=.sms.asm)
OBJ = $(SOURCE:.asm=.o)
GENERATED_FILES = $(OBJ) $(PATCHED) *.sym auto.makefile *.pcmenc *.ips *.bps

# Disable built-in rules
.SUFFIXES:

default: all

%.pcmenc: %
	$(PCMENC) -rto 1 -p 4 -dt1 12 -dt2 12 -dt3 423 "$^"

auto.makefile: $(SOURCE)
	$(WLAZ80) -t -M -MF $@ -o $(OBJ) $^

include auto.makefile

$(OBJ):
	$(WLAZ80) -o $(OBJ) $(SOURCE)

$(PATCHED): $(OBJ)
	echo [objects] > linkfile
	echo "$<" >> linkfile
	$(WLALINK) -d -r -v -S linkfile $@

$(PATCHED).ips: $(ORIGINAL) $(PATCHED)
	$(FLIPS) --create $(ORIGINAL) $(PATCHED) $@

$(PATCHED).bps: $(ORIGINAL) $(PATCHED)
	$(FLIPS) --create $(ORIGINAL) $(PATCHED) $@

all: $(PATCHED).ips $(PATCHED).bps

clean:
	del $(GENERATED_FILES)

