WLAZ80 = wla-z80.exe
WLALINK = wlalink.exe
FLIPS = flips.exe
PCMENC = ..\..\..\c\pcmenc\encoder\x64\Release\pcmenc.exe
7Z = "7z"

# The ROM filenames
ORIGINAL = SpaceHarrier.original.sms
PATCHED = SpaceHarrier.patched.sms
SOURCE = $(PATCHED:.patched.sms=.sms.asm)
OBJ = $(SOURCE:.asm=.o)

# Disable built-in rules
.SUFFIXES:

# Default targets are the patch files for our language
default: all

%.wav.pcmenc: %.wav
	$(PCMENC) -rto 1 -p 4 -dt1 12 -dt2 12 -dt3 423 "$<"

auto.makefile: $(SOURCE)
	$(WLAZ80) -M -o $(OBJ) $< > $@

include auto.makefile

$(OBJ):
	$(WLAZ80) -o $(OBJ) SpaceHarrier.sms.asm

$(PATCHED): $(OBJ)
	echo [objects] > linkfile
	echo "$<" >> linkfile
	$(WLALINK) -d -r -v -S linkfile $@

$(PATCHED).ips: $(ORIGINAL) $(PATCHED)
	$(FLIPS) --create $(ORIGINAL) $(PATCHED) $@

$(PATCHED).bps: $(ORIGINAL) $(PATCHED)
	$(FLIPS) --create $(ORIGINAL) $(PATCHED) $@

all: $(PATCHED).ips $(PATCHED).bps
