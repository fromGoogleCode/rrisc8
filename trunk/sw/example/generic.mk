# Hey Emacs, this is a -*- makefile -*-
# rRISC Makefile Template written by WangMengyin

# Define programs and commands.
CC = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE = avr-size
REMOVE = rm -f
CONVERT = ../../../tools//hex2mif/hex2mif.exe
COPY = cp -f

#architecture
MMCU = avr2

# Target file name
SOURCES = main.c

# Output format.
FORMAT = ihex

# Define Messages
MSG_BEGIN = -------- begin --------
MSG_END = --------  end  --------
MSG_CLEANING = Cleaning project:
MSG_CONFIG = Update MIF file and recompile Quartus project:
#OPTIMIZE = -O0 mofidied 2012-01-03
OPTIMIZE = -Os
SRC = $(SOURCES)
CFLAGS =-mmcu=$(MMCU) $(OPTIMIZE) -Wall -w
LDFLAGS = -Wl,--defsym=__stack=0x8003ff,-Map,$(PROJECT).map
MIF_PATH = "../../../syn/quartus ii/hex.mif"

all: program update

program: begin gccversion build size convert copy end

begin:
	@echo
	@echo $(MSG_BEGIN)
	
end:
	@echo $(MSG_END)
	@echo
	
gccversion:
	@$(CC) --version

build: hex lst

hex: $(PROJECT).hex

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -O ihex $(PROJECT).elf $(PROJECT).hex

$(PROJECT).elf: $(SOURCES)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(PROJECT).elf $(SOURCES)
	
lst: $(PROJECT).lst

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

size:
	$(SIZE) $(PROJECT).elf
	
convert:
	$(CONVERT) $(PROJECT).hex $(PROJECT).mif 4

copy:
	$(COPY) $(PROJECT).mif $(MIF_PATH)
	
# Target: clean project.
clean: begin clean_list end

clean_list :
	@echo
	@echo $(MSG_CLEANING)
	$(REMOVE) $(PROJECT).hex
	$(REMOVE) $(PROJECT).elf
	$(REMOVE) $(PROJECT).mif
	$(REMOVE) $(MIF_PATH)
	$(REMOVE) $(SRC:.c=.o)
	$(REMOVE) $(PROJECT).lst
	$(REMOVE) $(PROJECT).map
	
update:
	@echo
	@echo $(MSG_CONFIG)
	quartus_cdb --update_mif "../../../syn/quartus ii/rRISC8.qpf"
	quartus_asm "../../../syn/quartus ii/rRISC8.qpf"
	
