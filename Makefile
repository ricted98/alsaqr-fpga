# Define default variables
OPENOCD       ?= sudo $(shell which openocd)
GDB           ?= riscv64-unknown-elf-gdb
ADAPTER_SPEED ?= 1000
INTERFACE     ?= olimex-arm-usb-ocd-h
BOARD         ?= vcu-118
TARGET        ?= smp

# Set NUM_CORES based on core configuration
ifdef num-cores
	NUM_CORES = $(num-cores)
else
	NUM_CORES = 2
endif

# OpenOCD directory
OPENOCD_DIR   ?= openocd

# Initialize OpenOCD command arguments
OPENOCD_ARGS  += -s "$(OPENOCD_DIR)"

# Initialize OpenOCD commands
OPENOCD_CMDS  = -c "adapter speed $(ADAPTER_SPEED)" \
			   	-c "set _INTERFACE $(INTERFACE); echo \"Interface: $(INTERFACE)\"" \
			   	-c "set _BOARD $(BOARD); echo \"Board: $(BOARD)\"" \
				-c "set _NUM_CORES $(NUM_CORES); echo \"Number of cores: $(NUM_CORES)\"" \
			   	-c "set _TARGET $(TARGET); echo \"Target: $(TARGET)\"" \
			   	-f "openocd.cfg"

# Add init, reset, and halt commands
OPENOCD_CMDS += -c "init" -c "reset halt"

# Conditional programming of Hyperram interface
ifeq ($(use-hyper),1)
	OPENOCD_CMDS  += -c "mww 0x1a101018 0x18"
endif


# Conditional load of DTB file
ifeq ($(load-dtb),1)
	DTB_FILE      ?= ../alsaqr/cva6-sdk/alsaqr.dtb
	DTB_ADDR      ?= 0x81800000
	OPENOCD_CMDS  += -c "load_image $(DTB_FILE) $(DTB_ADDR)"
endif

# Append OpenOCD commands to arguments
OPENOCD_ARGS += $(OPENOCD_CMDS)

# Target to run OpenOCD
.PHONY: openocd
openocd:
	$(OPENOCD) $(OPENOCD_ARGS) -c "echo \"Ready for Remote Connections\""