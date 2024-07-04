# Define default variables
OPENOCD       ?= sudo $(shell which openocd)
GDB           ?= riscv64-unknown-elf-gdb
ADAPTER_SPEED ?= 1000
INTERFACE     ?= olimex-arm-usb-ocd-h
BOARD         ?= vcu-118
TARGET        ?= smp

# CVA6 SDK variables
CVA6_SDK_DIR  ?= cva6-sdk
IMAGES_DIR    ?= $(CVA6_SDK_DIR)/install64
PAYLOAD       ?= $(IMAGES_DIR)/fw_payload.elf

INITIAL_PC    ?= 0x80000000

# Set NUM_CORES based on core configuration
NUM_CORES     ?= 2
ifeq ($(origin num-cores), command line)
    NUM_CORES = $(num-cores)
endif

# OpenOCD directory
OPENOCD_DIR   ?= openocd

# Initialize OpenOCD command arguments
OPENOCD_ARGS  = -s "$(OPENOCD_DIR)"

# Initialize OpenOCD commands
OPENOCD_CMDS  = -c "adapter speed $(ADAPTER_SPEED)" \
               -c "set _INTERFACE $(INTERFACE); echo \"Interface: $(INTERFACE)\"" \
               -c "set _BOARD $(BOARD); echo \"Board: $(BOARD)\"" \
               -c "set _NUM_CORES $(NUM_CORES); echo \"Number of cores: $(NUM_CORES)\"" \
               -c "set _TARGET $(TARGET); echo \"Target: $(TARGET)\"" \
               -f "openocd.cfg" \
               -c "init" \
               -c "reset halt"

# Conditional programming of Hyperram interface
ifeq ($(use-hyper),1)
	OPENOCD_CMDS += -c "mww 0x1a101018 0x18"
endif

# Conditional load of DTB file
ifeq ($(load-dtb),1)
	DTB_FILE      ?= $(CVA6_SDK_DIR)/alsaqr.dtb
	DTB_ADDR      ?= 0x81800000
	OPENOCD_CMDS += -c "load_image $(DTB_FILE) $(DTB_ADDR)"
endif

# Append OpenOCD commands to arguments
OPENOCD_ARGS += $(OPENOCD_CMDS)

# Run OpenOCD to set up a GDB server
.PHONY: openocd
openocd:
	$(OPENOCD) $(OPENOCD_ARGS) -c "echo \"Ready for Remote Connections\""

# Run GDB to load the payload and execute it
.PHONY: gdb gdb-boot-linux
gdb:
	$(GDB) \
	-ex "target extended-remote :3333"
gdb-load-payload:
	$(GDB) \
	-ex "file $(PAYLOAD)" \
	-ex "target extended-remote :3333" \
	$(foreach i, $(shell seq 1 $(NUM_CORES)), -ex "thread $(i)" -ex "set \$$pc=$(INITIAL_PC)") \
	-ex "load" \
	-ex "c"
