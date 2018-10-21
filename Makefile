# Quiet output
Q ?= @

# Where are we and where is all the stuff?
ROOTDIR       := .
BUILDSYSDIR   := $(ROOTDIR)/buildsys
RTOSDIR       := $(ROOTDIR)/freertos
BUILDDIR      := $(ROOTDIR)/artifacts
TARGET        := makefile_example

# Defaults
TOOLCHAIN     := arm-none-eabi
CC            := $(TOOLCHAIN)-gcc
AS            := $(TOOLCHAIN)-gcc -x assembler-with-cpp
CP            := $(TOOLCHAIN)-objcopy
AR            := $(TOOLCHAIN)-ar
SZ            := $(TOOLCHAIN)-size
GDB           := $(TOOLCHAIN)-gdb
HEX           := $(CP) -O ihex
BIN           := $(CP) -O binary -S
MKDIR         := mkdir
RM            := rm -rf

# List of C defines
DEFINES       := -D__FPU_PRESENT=1

# Optimization
OPTIMIZATION  := -Os
OPTIMIZATION  += -ggdb

# Warning flags
WARNING       := -Wall
WARNING       += -Wextra
WARNING       += -Wno-unused-local-typedefs
WARNING       += -Werror

# Rando flags
CFLAGS        := -mfloat-abi=hard
CFLAGS        += -mcpu=cortex-m4
CFLAGS        += -mfpu=fpv4-sp-d16
#CFLAGS        += -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"
CFLAGS        += -std=gnu11
CFLAGS        += $(OPTIMIZATION)
CFLAGS        += $(DEFINES)

# LD flags
LDFLAGS       := -Wl,--gc-sections -lc -lnosys
LDFLAGS       += -Wl,--no-wchar-size-warning
LDFLAGS       += -mfloat-abi=hard

# Linker script
LINKERSCRIPT  := $(BUILDSYSDIR)/stm32_flash.ld

##################################################################
# Our application source files
C_SOURCES     := $(wildcard $(ROOTDIR)/src/*.c)
ASM_SOURCES   := $(wildcard $(ROOTDIR)/src/*.s)

# Our Include directories
INCDIRS       := $(ROOTDIR)/src

# Submakes
include $(RTOSDIR)/freertos.mk
##################################################################

# Includes
INCLUDES      := $(patsubst %, -I%, $(INCDIRS))

# Objects
OBJECTS       := $(addprefix $(BUILDDIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS       += $(addprefix $(BUILDDIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# Set up some vpath stuff so that we pretend all the c and s files are in the same places
vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

print-% : ; @echo $* = $($*)

# Targets
all: $(BUILDDIR)/$(TARGET).elf $(BUILDDIR)/$(TARGET).hex $(BUILDDIR)/$(TARGET).bin

$(BUILDDIR)/%.o: %.c Makefile | $(BUILDDIR)
	$(CC) -c $(CFLAGS) $(INCLUDES) $< -o $@

$(BUILDDIR)/%.o: %.s Makefile | $(BUILDDIR)
	$(AS) -c $(ASFLAGS) $< -o $@

$(BUILDDIR)/$(TARGET).elf: $(OBJECTS) Makefile | $(BUILDDIR)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILDDIR)/%.hex: $(BUILDDIR)/%.elf | $(BUILDDIR)
	$(HEX) $< $@

$(BUILDDIR)/%.bin: $(BUILDDIR)/%.elf | $(BUILDDIR)
	$(BIN) $< $@

$(BUILDDIR):
	$(MKDIR) $@

.PHONY: clean
clean:
	$(RM) $(BUILDDIR)
	$(RM) .dep

.PHONY: date
date:
	cowsay $(shell date)

.PHONY: gdbserver
gdbserver:
	JLinkGDBServer -If SWD -Device STM32xxx -Speed 1000

.PHONY: gdb
gdb: $(BUILDDIR)/$(TARGET).elf
	$(GDB) -ex "target remote localhost 2331" -ex "mon reset" -ex "mon halt" $<

.PHONY: ctags
	ctags --exclude=docs --exclude=$(BUILDDIR) -R

# Dependencies
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

